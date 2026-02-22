# Syncs members for a single faction from the Torn API
class SyncFactionMembersJob < OwnerApiJob
  def perform(faction_id)
    faction = Faction.find(faction_id)
    api_key = OwnerCredentials.api_key
    members = TornApi::Faction::Members.new(api_key, faction.torn_id).fetch

    member_torn_ids = members.map(&:id)

    # Clear faction_id for users no longer in faction
    User.where(faction_id: faction.id)
        .where.not(torn_id: member_torn_ids)
        .update_all(faction_id: nil)

    members.each do |member|
      user = User.find_or_initialize_by(torn_id: member.id)
      user.assign_attributes(
        name: member.name,
        level: member.level,
        faction_id: faction.id,
        fallen: member.status_state == "Fallen"
      )
      user.save!
    end

    Rails.logger.info "SyncFactionMembersJob: Synced #{members.size} members for faction #{faction.name} [#{faction.torn_id}]"
  rescue TornApi::ApiError => e
    Rails.logger.error "SyncFactionMembersJob: Failed to sync faction #{faction.torn_id}: #{e.message}"
  end
end
