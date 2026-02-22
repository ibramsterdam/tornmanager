# Fetches members for a single faction from the Torn API and creates/updates user records
class FetchFactionMembersJob < OwnerApiJob
  def perform(faction_torn_id)
    members = TornApi::Faction::Members.new(OwnerCredentials.api_key, faction_torn_id).fetch

    members.each do |member|
      User.find_or_create_by(torn_id: member.id) do |user|
        user.name = member.name
        user.level = member.level
        # api_key is nil until they log in
      end
    end

    Rails.logger.debug "FetchFactionMembersJob: Fetched #{members.size} members for faction #{faction_torn_id}"
  rescue TornApi::ApiError => e
    Rails.logger.error "FetchFactionMembersJob: Failed to fetch faction #{faction_torn_id}: #{e.message}"
  end
end
