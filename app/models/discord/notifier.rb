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

    def self.send_to_channel(channel_id, content: nil, embed: nil)
      return if Rails.env.test?

      token = Rails.application.credentials.dig(:discord, :bot_token)
      return unless token

      payload = {}
      payload[:content] = content if content
      payload[:embeds] = [ embed ] if embed

      Thread.new do
        uri = URI("https://discord.com/api/v10/channels/#{channel_id}/messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bot #{token}"
        request["Content-Type"] = "application/json"
        request.body = payload.to_json

        response = http.request(request)
        unless response.code.to_i == 200
          Rails.logger.error("[Discord::Notifier] Channel message failed (#{response.code}): #{response.body}")
        end
      rescue => e
        Rails.logger.error("[Discord::Notifier] Failed: #{e.message}")
      end
    end
  end
end
