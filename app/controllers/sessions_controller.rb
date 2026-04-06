class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    api_key = params[:api_key].to_s.strip

    begin
      key_info = TornApi::Key::Info.new(api_key).fetch
      profile = TornApi::User::Profile.new(api_key).fetch

      if profile.nil?
        return redirect_to new_session_path, alert: "Could not fetch profile from Torn API."
      end

      user = User.find_by(torn_id: profile.id) || User.new

      user.assign_attributes(
        torn_id: profile.id,
        name: profile.name,
        level: profile.level,
        profile_image: profile.image
      )

      torn_faction_id = key_info.user.faction_id
      if torn_faction_id.present? && torn_faction_id > 0
        faction = Faction.find_by(torn_id: torn_faction_id)

        unless faction
          begin
            faction_name = TornApi::Faction::Basic.new(api_key, torn_faction_id).name
            faction = Faction.create!(torn_id: torn_faction_id, name: faction_name, setup_completed: false)
            sync_faction_members(faction)
          rescue StandardError => e
            Rails.logger.warn("Failed to create faction #{torn_faction_id} on login: #{e.message}")
            faction = nil
          end
        end

        user.faction_id = faction.id if faction
      end

      user.save!
      user.set_api_key!(api_key, key_info.access.type)

      start_new_session_for user
      notify_sign_in(user)

      redirect_to after_authentication_url
    rescue TornApi::InvalidKeyError
      redirect_to new_session_path, alert: "Invalid Torn API key."
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("User upsert failed: #{e.record.errors.full_messages}")
      redirect_to new_session_path, alert: "Could not create user profile."
    rescue => e
      Rails.logger.error("Unexpected login error: #{e.class} - #{e.message}")
      redirect_to new_session_path, alert: "Unexpected error. Please try again."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end

  private

  def notify_sign_in(user)
    Discord::Notifier.notify(
      webhook_key: :notifications_webhook_url,
      embed: {
        title: "Sign In",
        description: "[#{user.name} [#{user.torn_id}]](https://www.torn.com/profiles.php?XID=#{user.torn_id})",
        color: 5_025_616,
        footer: { text: "TornManager" },
        timestamp: Time.current.iso8601
      }
    )
  end
  def sync_faction_members(faction)
    members = TornApi::Faction::Members.new(AdminCredentials.api_key, faction.torn_id).fetch

    members.each do |member|
      user = User.find_or_initialize_by(torn_id: member.id)
      user.assign_attributes(
        name: member.name,
        level: member.level,
        position: member.position,
        faction_id: faction.id,
        fallen: member.status_state == "Fallen"
      )
      user.save!
    end
  end
end
