module Daily
  class FactionMembershipSyncJob < ApplicationJob
    queue_as :default

    def perform
      Faction.tracked.find_each do |faction|
        sync_faction_members(faction)
      end
    end

    def sync_faction_members(faction)
      api_key = OwnerCredentials.api_key
      members = TornApi::Faction::Members.new(api_key, faction.torn_id).fetch

      member_torn_ids = members.map(&:id)

      # Clear faction_id for users no longer in faction
      User.where(faction_id: faction.id)
          .where.not(torn_id: member_torn_ids)
          .update_all(faction_id: nil)

      # Create/update users for current members
      members.each do |member|
        user = User.find_or_initialize_by(torn_id: member.id)
        user.assign_attributes(
          name: member.name,
          level: member.level,
          faction_id: faction.id
        )
        user.save!
      end

      Rails.logger.info "FactionMembershipSyncJob: Synced #{members.size} members for faction #{faction.name} [#{faction.torn_id}]"
      ::Appsignal.set_gauge("faction_sync.members_synced", members.size, faction_id: faction.torn_id) if defined?(::Appsignal)
    rescue TornApi::ApiError => e
      Rails.logger.error "FactionMembershipSyncJob: Failed to sync faction #{faction.torn_id}: #{e.message}"
      ::Appsignal.send_error(e) if defined?(::Appsignal)
    end
  end
end
