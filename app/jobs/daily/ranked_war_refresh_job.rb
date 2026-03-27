module Daily
  class RankedWarRefreshJob < ApplicationJob
    queue_as :default

    def perform
      Faction.where(setup_completed: true).joins(:api_keys).where(api_keys: { type: "ApiKey::Torn" }).distinct.find_each do |faction|
        BackfillRankedWarsJob.perform_later(faction.id)
      end
    end
  end
end
