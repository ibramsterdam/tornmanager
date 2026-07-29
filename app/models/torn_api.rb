require "net/http"
require "json"

module TornApi
  class InvalidKeyError < StandardError; end
  class ApiError < StandardError; end
  class RateLimitError < ApiError; end
  # Torn-side hiccups that heal on their own (5xx, empty payloads during the
  # nightly stats-cache rebuild, "backend error, please try again") — jobs
  # retry these with a delay instead of failing.
  class TransientError < ApiError; end
  # Torn returned an empty payload. For live fetches this is transient (cache
  # rebuild); for historical backfills it usually means no data exists for
  # that player/date and the date should be tombstoned, not retried forever.
  class NoDataError < TransientError; end
  class NotFoundError < ApiError; end
  class TimeoutError < ApiError; end

  class Base
    DEFAULT_PARAMS = { comment: "tmanager" }.freeze
    BASE_URL = "https://api.torn.com"
    DEFAULT_READ_TIMEOUT = 10
    DEFAULT_OPEN_TIMEOUT = 5
    MAX_RETRIES = 2

    attr_reader :api_key

    def initialize(api_key)
      raise InvalidKeyError, "No API key provided" if api_key.blank?
      @api_key = api_key
    end

    def get(path, params = {}, retries: 0)
      start_time = Time.current
      api_params = params.is_a?(Hash) ? params : {}
      merged_params = DEFAULT_PARAMS.merge(api_params)
      uri = URI("#{BASE_URL}/#{path}")
      uri.query = URI.encode_www_form(merged_params)

      log_request(uri)

      RateLimiter.acquire!(api_key)
      response = perform_request(uri)
      body = parse_response(response, path)

      check_for_errors(body)

      response_time = ((Time.current - start_time) * 1000).to_i
      log_api_call(path, merged_params, "success", response_time, body["_metadata"])
      log_success(uri)

      body
    rescue TransientError => e
      handle_transient(uri, api_params, e, retries, start_time)
    rescue InvalidKeyError, ApiError => e
      response_time = ((Time.current - start_time) * 1000).to_i
      log_api_call(path, merged_params, "error", response_time, nil, e.message)
      notify_discord_error(path, merged_params, e) unless e.is_a?(InvalidKeyError) || e.is_a?(RateLimitError) || e.is_a?(NotFoundError)
      invalidate_api_key! if e.is_a?(InvalidKeyError)
      raise
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      handle_timeout(uri, api_params, e, retries, start_time)
    rescue JSON::ParserError => e
      response_time = ((Time.current - start_time) * 1000).to_i
      log_api_call(path, merged_params, "error", response_time, nil, "JSON parse error: #{e.message}")
      Rails.logger.error("JSON parse error for #{uri}: #{e.message}")
      raise ApiError, "Invalid JSON response from Torn API"
    rescue Net::HTTPError, SocketError => e
      handle_network_error(uri, api_params, e, retries, start_time)
    end

    private

    def perform_request(uri)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        read_timeout: DEFAULT_READ_TIMEOUT,
        open_timeout: DEFAULT_OPEN_TIMEOUT
      ) do |http|
        req = Net::HTTP::Get.new(uri)
        req["accept"] = "application/json"
        req["Authorization"] = "ApiKey #{api_key}"
        http.request(req)
      end
    end

    def parse_response(response, path = nil)
      status = response.code.to_i
      unless status == 200
        Rails.logger.error("HTTP #{status} from Torn API: #{response.body[0..500]}")
        if status >= 500
          notify_torn_degraded(path, status)
          raise TransientError, "Torn API request failed (HTTP #{status})"
        end
        raise ApiError, "Torn API request failed (HTTP #{status})"
      end

      JSON.parse(response.body)
    end

    def check_for_errors(body)
      return unless body["error"]
      handle_api_error(body["error"])
    end

    def handle_api_error(error)
      error_code = error["code"]
      error_msg = error["error"]

      case error_code
      # Key errors — user-resolvable, no Discord alert needed
      when 1      then raise InvalidKeyError, "API key is empty"
      when 2      then raise InvalidKeyError, "Invalid API key"
      when 10     then raise InvalidKeyError, "Key owner is in federal jail"
      when 12     then raise InvalidKeyError, "Key read error"
      when 13     then raise InvalidKeyError, "Key temporarily disabled due to owner inactivity"
      when 16     then raise InvalidKeyError, "Access level of this key is not high enough"
      when 18     then raise InvalidKeyError, "API key has been paused by the owner"

      # Rate limiting
      when 5      then raise RateLimitError, "Too many requests"
      when 8      then raise RateLimitError, "IP blocked for abuse"
      when 14     then raise RateLimitError, "Daily read limit reached"

      # Bad request — wrong ID or selections
      when 6      then raise NotFoundError, "Incorrect ID: #{error_msg}"
      when 7      then raise NotFoundError, "Requested data is private"

      # Torn infrastructure issues — 15/17 heal on retry, 9/24 can last hours
      when 9      then raise ApiError, "Torn API is currently disabled"
      when 17     then raise TransientError, "Torn backend error, please try again"
      when 24     then raise ApiError, "Torn API temporarily closed"

      # Request parameter errors
      when 3      then raise ApiError, "Wrong type requested: #{error_msg}"
      when 4      then raise ApiError, "Wrong fields requested: #{error_msg}"
      when 11     then raise ApiError, "Can only change API key once every 60 seconds"
      when 15     then raise TransientError, "Temporary error: #{error_msg}"
      when 19     then raise ApiError, "Must be migrated to crimes 2.0"
      when 20     then raise ApiError, "Race not yet finished"
      when 21     then raise ApiError, "Incorrect category: #{error_msg}"
      when 22     then raise ApiError, "Selection only available in API v1"
      when 23     then raise ApiError, "Selection only available in API v2"
      when 25     then raise ApiError, "Invalid stat requested: #{error_msg}"
      when 26     then raise ApiError, "Only category or stats can be requested"
      when 27     then raise ApiError, "Must be migrated to organized crimes 2.0"
      when 28     then raise ApiError, "Incorrect log ID"
      when 29     then raise ApiError, "Category selection not available for interaction logs"

      else
        raise ApiError, "API error #{error_code}: #{error_msg}"
      end
    end

    def handle_transient(uri, api_params, error, retries, start_time)
      if retries < MAX_RETRIES
        Rails.logger.warn("Transient Torn error for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        sleep(1 * (retries + 1))
        get(uri.path.sub(/^\//, ""), api_params, retries: retries + 1)
      else
        response_time = ((Time.current - start_time) * 1000).to_i
        log_api_call(uri.path.sub(/^\//, ""), api_params, "error", response_time, nil, error.message)
        Rails.logger.error("Transient Torn error for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        raise error
      end
    end

    def handle_timeout(uri, api_params, error, retries, start_time)
      if retries < MAX_RETRIES
        Rails.logger.warn("Timeout for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        sleep(1 * (retries + 1))
        get(uri.path.sub(/^\//, ""), api_params, retries: retries + 1)
      else
        response_time = ((Time.current - start_time) * 1000).to_i
        log_api_call(uri.path.sub(/^\//, ""), api_params, "error", response_time, nil, "Timeout after #{MAX_RETRIES} retries")
        Rails.logger.error("Timeout for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        raise TimeoutError, "Torn API request timed out after #{MAX_RETRIES} retries"
      end
    end

    def handle_network_error(uri, api_params, error, retries, start_time)
      if retries < MAX_RETRIES
        Rails.logger.warn("Network error for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        sleep(1 * (retries + 1))
        get(uri.path.sub(/^\//, ""), api_params, retries: retries + 1)
      else
        response_time = ((Time.current - start_time) * 1000).to_i
        log_api_call(uri.path.sub(/^\//, ""), api_params, "error", response_time, nil, "Network error: #{error.message}")
        Rails.logger.error("Network error for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        raise ApiError, "Network error: #{error.message}"
      end
    end

    def parse_query(query_string)
      return {} unless query_string
      URI.decode_www_form(query_string).to_h.symbolize_keys
    end

    def log_request(uri)
      Rails.logger.info("TornAPI request: #{uri.path}?#{uri.query&.gsub(/key=[^&]+/, 'key=[REDACTED]')}")
    end

    def log_success(uri)
      Rails.logger.debug("TornAPI success: #{uri.path}")
    end

    def log_api_call(endpoint, params, status, response_time, metadata, error_message = nil)
      target_user = resolve_api_key_owner

      unless target_user
        Rails.logger.debug("log_api_call skipped: no user found for api_key=#{api_key[0..5]}...")
        return
      end

      ApiCall.create!(
        user: target_user,
        faction_id: target_user.faction_id,
        api_key: api_key,
        endpoint: endpoint,
        selections: params.except(:comment, :striptags).to_json,
        response_time: response_time,
        status: status,
        error_message: error_message,
        torn_api_timestamp: metadata&.dig("timestamp")
      )
    rescue => e
      Rails.logger.error("Failed to log API call: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
    end

    def notify_discord_error(path, params, error)
      cache_key = "discord_api_error:#{error.class}:#{sanitize_path(path)}"
      return if Rails.cache.exist?(cache_key)

      Rails.cache.write(cache_key, true, expires_in: 10.minutes)

      selections = params[:selections]
      owner = resolve_api_key_owner
      owner_label = if owner
        faction = owner.faction
        faction ? "#{owner.name} [#{faction.name}]" : owner.name
      else
        "Unknown"
      end

      Discord::Notifier.notify(
        webhook_key: :error_webhook_url,
        embed: {
          title: "Torn API Error",
          description: "```#{error.message}```",
          color: 15_158_332,
          fields: [
            { name: "Endpoint", value: sanitize_path(path), inline: true },
            { name: "Selections", value: selections || "N/A", inline: true },
            { name: "Owner", value: owner_label, inline: true },
            { name: "Key", value: "#{api_key[0..7]}...", inline: true },
            { name: "Environment", value: Rails.env, inline: true }
          ],
          footer: { text: "TornManager API Monitor" },
          timestamp: Time.current.iso8601
        }
      )
    rescue => e
      Rails.logger.error("[Discord API Error Notify] Failed: #{e.message}")
    end

    def sanitize_path(path)
      path.gsub(%r{/\d+(?=/|$)}, "/{id}")
    end

    def notify_torn_degraded(path, status)
      return unless Rails.env.production?

      cache_key = "torn_degraded:#{sanitize_path(path)}"
      return if Rails.cache.exist?(cache_key)

      Rails.cache.write(cache_key, true, expires_in: 10.minutes)

      Discord::Notifier.send_to_channel(
        "1491152993859670167",
        embed: {
          title: ":red_circle: Torn API Degraded",
          description: "```Torn API request failed (HTTP #{status})```\n**Endpoint:** `#{sanitize_path(path)}`\n\nTornManager services may be affected. Next health check <t:#{(Time.current + 5.minutes).to_i}:R>.",
          color: 15_158_332,
          footer: { text: "TornManager Status Monitor" },
          timestamp: Time.current.iso8601
        }
      )

      TornApiHealthCheckJob.perform_later(path)
    rescue => e
      Rails.logger.error("[Discord Torn Degraded Notify] Failed: #{e.message}")
    end

    def invalidate_api_key!
      return if api_key == AdminCredentials.api_key

      record = ::ApiKey.find_by(key: api_key)
      return unless record

      if record.faction_id?
        record.faction.handle_invalid_api_key!
      else
        record.destroy!
      end
    rescue => e
      Rails.logger.error("[TornAPI] Failed to invalidate API key: #{e.message}")
    end

    def resolve_api_key_owner
      @resolved_user ||= begin
        found = ::User.find_by_api_key(api_key)
        return found if found

        ::User.find_by(torn_id: ::User::ADMIN_TORN_ID) if api_key == AdminCredentials.api_key
      end
    end
  end
end
