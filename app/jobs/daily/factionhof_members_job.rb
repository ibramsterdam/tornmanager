class Daily::FactionhofMembersJob < ApplicationJob
  queue_as :default

  FACTION_BATCH_SIZE = 50
  TOP_FACTIONS_COUNT = 4000

  def perform
    api_key = Rails.application.credentials.dig(:bram, :api_key)
    # 20 calls
    top_factions = (0...TOP_FACTIONS_COUNT).step(100).flat_map do |offset|
      TornApi::Torn::Factionhof.new(api_key, offset:).fetch
    end
    faction_ids = top_factions.map(&:torn_id)

    # enqueue 50 api calls 40 times, so spread over 20 minutes
    faction_ids.each_slice(FACTION_BATCH_SIZE).with_index do |batch_ids, i|
      FactionMembersJob.set(wait: i.minutes).perform_later(batch_ids)
    end
  end
end
