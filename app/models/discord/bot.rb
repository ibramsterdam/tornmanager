require "discordrb"

module Discord
  class Bot
    attr_reader :client

    def initialize
      token = Rails.application.credentials.dig(:discord, :bot_token)
      raise "Discord bot_token not configured" unless token

      @client = Discordrb::Bot.new(
        token: token,
        intents: [ :server_members ]
      )
    end

    def start
      register_commands
      register_events
      Rails.logger.info("[Discord::Bot] Starting...")
      client.run
    end

    private

    def register_commands
      guild_id = Rails.application.credentials.dig(:discord, :guild_id)
      existing = client.get_application_commands(server_id: guild_id)

      unless existing.any? { |cmd| cmd.name == "verify" }
        client.register_application_command(:verify, "Verify your Torn account", server_id: guild_id)
        Rails.logger.info("[Discord::Bot] Registered /verify command")
      end
    end

    def register_events
      client.ready do |_event|
        Rails.logger.info("[Discord::Bot] Online and ready")
      end

      client.member_join do |event|
        Discord::Verifier.new(event).call
      end

      client.application_command(:verify) do |event|
        Discord::Verifier.new(event).verify
      end
    end
  end
end
