module Daily
  class ValidateFactionKeysJob < ApplicationJob
    queue_as :default

    def perform
      validate_faction_keys
      validate_user_keys
    end

    private

    def validate_faction_keys
      ApiKey::Torn.where.not(faction_id: nil).includes(:faction).find_each do |api_key|
        info = TornApi::Key::Info.new(api_key.key).fetch

        unless info.access.faction == true
          Rails.logger.info("[ValidateKeys] Faction #{api_key.faction.name}: no faction access, destroying key")
          destroy_faction_key(api_key)
          next
        end

        api_key.update!(faction_access: true) unless api_key.faction_access?
      rescue TornApi::InvalidKeyError
        Rails.logger.info("[ValidateKeys] Faction #{api_key.faction.name}: invalid key, destroying")
        destroy_faction_key(api_key)
      rescue TornApi::ApiError => e
        Rails.logger.warn("[ValidateKeys] Faction #{api_key.faction.name}: #{e.message}")
      ensure
        sleep 1
      end
    end

    def validate_user_keys
      ApiKey::Torn.where.not(user_id: nil).includes(:user).find_each do |api_key|
        TornApi::Key::Info.new(api_key.key).fetch
      rescue TornApi::InvalidKeyError
        Rails.logger.info("[ValidateKeys] User #{api_key.user.name} [#{api_key.user.torn_id}]: invalid key, clearing")
        api_key.destroy!
      rescue TornApi::ApiError => e
        Rails.logger.warn("[ValidateKeys] User #{api_key.user.name} [#{api_key.user.torn_id}]: #{e.message}")
      ensure
        sleep 1
      end
    end

    def destroy_faction_key(api_key)
      faction = api_key.faction
      api_key.destroy!
      faction.update!(setup_completed: false)
    end
  end
end
