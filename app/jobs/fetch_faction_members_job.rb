class FetchFactionMembersJob < AdminApiJob
  def perform(faction_torn_id)
    members = TornApi::Faction::Members.new(AdminCredentials.api_key, faction_torn_id).fetch

    members.each do |member|
      User.find_or_create_by(torn_id: member.id) do |user|
        user.name = member.name
        user.level = member.level
      end
    end

    Rails.logger.debug "FetchFactionMembersJob: Fetched #{members.size} members for faction #{faction_torn_id}"
  rescue TornApi::ApiError => e
    Rails.logger.error "FetchFactionMembersJob: Failed to fetch faction #{faction_torn_id}: #{e.message}"
  end
end
