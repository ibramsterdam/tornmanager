# Fetches a single page of faction HOF rankings from the Torn API
class FetchFactionHofPageJob < TornApiJob
  # @param offset [Integer] The offset for pagination (0, 100, 200, etc.)
  def perform(offset)
    factions = TornApi::Torn::Factionhof.new(OwnerCredentials.api_key, offset:).fetch

    # Schedule individual member fetch jobs for each faction
    factions.each do |faction|
      FetchFactionMembersJob.perform_later(faction.torn_id)
    end

    Rails.logger.info "FetchFactionHofPageJob: Fetched #{factions.size} factions at offset #{offset}"
  end
end
