module Discord
  class Verifier
    def initialize(event)
      @event = event
      @guild_id = Rails.application.credentials.dig(:discord, :guild_id)
      @verified_role_id = Rails.application.credentials.dig(:discord, :verified_role_id)
    end

    def call
      return unless home_server?

      discord_id = @event.user.id.to_s
      Rails.logger.info("[Discord::Verifier] New member: #{@event.user.name} (#{discord_id})")

      torn_user = lookup_torn_user(discord_id)

      if torn_user
        apply_verification(torn_user)
      else
        send_link_instructions
      end
    rescue => e
      Rails.logger.error("[Discord::Verifier] #{e.class}: #{e.message}")
    end

    def verify
      return unless home_server?

      discord_id = @event.user.id.to_s
      torn_user = lookup_torn_user(discord_id)

      if torn_user
        name = apply_verification(torn_user)
        @event.respond(
          content: "Verified successfully! Welcome [#{name} [#{torn_user.user_id}]](https://www.torn.com/profiles.php?XID=#{torn_user.user_id})",
          ephemeral: true
        )
      else
        @event.respond(
          content: "Could not find your Torn account. Make sure you've linked your Discord to Torn:\n" \
                   "<https://www.torn.com/forums.php#/p=threads&f=14&t=16052509&b=0&a=0>\n\n" \
                   "Once linked, run `/verify` again.",
          ephemeral: true
        )
      end
    rescue => e
      Rails.logger.error("[Discord::Verifier] Slash command error: #{e.class}: #{e.message}")
      @event.respond(content: "Something went wrong. Please try again later.", ephemeral: true)
    end

    private

    def home_server?
      @event.server.id.to_s == @guild_id.to_s
    end

    def lookup_torn_user(discord_id)
      api_key = AdminCredentials.api_key
      return nil unless api_key

      TornApi::User::Discord.new(api_key, discord_id).fetch
    rescue TornApi::ApiError => e
      Rails.logger.error("[Discord::Verifier] Torn API error: #{e.message}")
      nil
    end

    def apply_verification(torn_user)
      member = @event.server.member(@event.user.id)
      name = fetch_torn_name(torn_user.user_id)
      display_name = "#{name} [#{torn_user.user_id}]"

      begin
        member.nick = display_name
      rescue => e
        Rails.logger.warn("[Discord::Verifier] Cannot set nickname for #{@event.user.name}: #{e.message}")
      end

      begin
        member.add_role(@verified_role_id.to_i)
      rescue => e
        Rails.logger.warn("[Discord::Verifier] Cannot add role for #{@event.user.name}: #{e.message}")
      end

      Rails.logger.info("[Discord::Verifier] Verified #{@event.user.name} as #{display_name}")
      name
    end

    def send_link_instructions
      @event.user.pm(
        "Welcome to the TornManager Discord!\n\n" \
        "I couldn't verify your Torn account. To get verified:\n" \
        "1. Link your Discord to Torn by following this guide by IBF: " \
        "<https://www.torn.com/forums.php#/p=threads&f=14&t=16052509&b=0&a=0>\n" \
        "2. Once linked, come back and type `/verify` in any channel."
      )
    rescue Discordrb::Errors::NoPermission
      Rails.logger.warn("[Discord::Verifier] Cannot DM #{@event.user.name}")
    end

    def fetch_torn_name(torn_id)
      user = ::User.find_by(torn_id: torn_id)
      return user.name if user

      api_key = AdminCredentials.api_key
      return "Player" unless api_key

      response = TornApi::Base.new(api_key).get("v2/user/#{torn_id}/profile", {})
      response.dig("profile", "name") || "Player"
    rescue => e
      Rails.logger.warn("[Discord::Verifier] Failed to fetch name for #{torn_id}: #{e.message}")
      "Player"
    end
  end
end
