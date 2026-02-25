class FetchFactionHofPageJob < OwnerApiJob
  def perform(offset)
    factions = TornApi::Torn::Factionhof.new(OwnerCredentials.api_key, offset:).fetch

    factions.each do |faction|
      FetchFactionMembersJob.perform_later(faction.torn_id)
    end

    Rails.logger.info "FetchFactionHofPageJob: Fetched #{factions.size} factions at offset #{offset}"
  end
end
