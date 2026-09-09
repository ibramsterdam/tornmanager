require "net/http"
require "json"

module Discord
  class BotChannel
    API_BASE = "https://discord.com/api/v10".freeze

    def initialize(token, channel_id)
      @token = token
      @channel_id = channel_id
    end

    def configured?
      @token.present? && @channel_id.present?
    end

    def post(content: nil, embed: nil, allowed_mentions: nil)
      return unless configured?

      uri = URI("#{API_BASE}/channels/#{@channel_id}/messages")
      response = request(Net::HTTP::Post.new(uri), payload(content, embed, allowed_mentions))
      return unless success?(response)

      JSON.parse(response.body)["id"]
    rescue JSON::ParserError => e
      Rails.logger.error("[Discord::BotChannel] Unparseable response: #{e.message}")
      nil
    end

    def edit(message_id, content: nil, embed: nil, allowed_mentions: nil)
      return unless configured? && message_id.present?

      uri = URI("#{API_BASE}/channels/#{@channel_id}/messages/#{message_id}")
      response = request(Net::HTTP::Patch.new(uri), payload(content, embed, allowed_mentions))
      success?(response)
    end

    private

    def payload(content, embed, allowed_mentions)
      body = {}
      body[:content] = content if content
      body[:embeds] = [ embed ] if embed
      body[:allowed_mentions] = allowed_mentions if allowed_mentions
      body
    end

    def request(req, body)
      uri = req.uri
      req["Authorization"] = "Bot #{@token}"
      req["Content-Type"] = "application/json"
      req.body = body.to_json

      Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 10, open_timeout: 5) do |http|
        http.request(req)
      end
    rescue => e
      Rails.logger.error("[Discord::BotChannel] Request failed: #{e.message}")
      nil
    end

    def success?(response)
      return false unless response

      if response.code.to_i.between?(200, 299)
        true
      else
        Rails.logger.error("[Discord::BotChannel] HTTP #{response.code}: #{response.body.to_s[0..300]}")
        false
      end
    end
  end
end
