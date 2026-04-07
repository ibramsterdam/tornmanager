class TornApiHealthCheckJob < ApplicationJob
  queue_as :default

  RECHECK_INTERVAL = 5.minutes
  DISCORD_CHANNEL_ID = "1491152993859670167"

  limits_concurrency to: 1, key: ->(endpoint) { "torn_health_#{endpoint}" }

  def perform(endpoint)
    return unless Rails.env.production?

    api_key = AdminCredentials.api_key
    return unless api_key

    client = TornApi::Base.new(api_key)
    client.get(endpoint)

    sanitized = endpoint.gsub(%r{/\d+(?=/|$)}, "/{id}")
    Rails.cache.delete("torn_degraded:#{sanitized}")

    Discord::Notifier.send_to_channel(
      DISCORD_CHANNEL_ID,
      embed: {
        title: ":green_circle: Torn API Recovered",
        description: "**Endpoint:** `#{sanitized}`\n\nResponding normally again. Services restored.",
        color: 0x22c55e,
        footer: { text: "TornManager Status Monitor" },
        timestamp: Time.current.iso8601
      }
    )
  rescue TornApi::ApiError => e
    if e.message.include?("HTTP 5")
      sanitized = endpoint.gsub(%r{/\d+(?=/|$)}, "/{id}")

      Discord::Notifier.send_to_channel(
        DISCORD_CHANNEL_ID,
        embed: {
          title: ":yellow_circle: Torn API Still Degraded",
          description: "**Endpoint:** `#{sanitized}`\n\nStill returning errors. Next health check <t:#{(Time.current + RECHECK_INTERVAL).to_i}:R>.",
          color: 0xeab308,
          footer: { text: "TornManager Status Monitor" },
          timestamp: Time.current.iso8601
        }
      )

      TornApiHealthCheckJob.set(wait: RECHECK_INTERVAL).perform_later(endpoint)
    end
  end
end
