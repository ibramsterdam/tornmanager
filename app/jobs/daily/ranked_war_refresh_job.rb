module Daily
  class RankedWarRefreshJob < ApplicationJob
    queue_as :default

    def perform
      Faction.where(setup_completed: true).joins(:faction_setting).where.not(faction_settings: { torn_api_key: [ nil, "" ] }).find_each do |faction|
        BackfillRankedWarsJob.perform_later(faction.id)
      end
    end
  end
end
