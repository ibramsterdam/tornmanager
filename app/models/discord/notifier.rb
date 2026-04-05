require "net/http"
require "json"

module Discord
  class Notifier
    def initialize(webhook_key: :default_webhook_url)
      @webhook_url = Rails.application.credentials.dig(:discord, webhook_key)
    end

    def send(content: nil, embed: nil)
      return if Rails.env.test?
      return unless @webhook_url

      payload = {}
      payload[:content] = content if content
      payload[:embeds] = [ embed ] if embed

      Thread.new do
        uri = URI(@webhook_url)
        Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")
      rescue => e
        Rails.logger.error("[Discord::Notifier] Failed: #{e.message}")
      end
    end

    def self.notify(webhook_key: :default_webhook_url, content: nil, embed: nil)
      new(webhook_key: webhook_key).send(content: content, embed: embed)
    end
  end
end
