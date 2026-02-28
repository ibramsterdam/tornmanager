class ClearBackfillStatusJob < ApplicationJob
  queue_as :faction_api

  def perform(faction_id)
    faction = Faction.find(faction_id)
    faction.clear_backfill_status!

    Rails.logger.info("Cleared backfill status for faction #{faction.name}")
  end
end
