class Factions::Leadership::FactionDataController < Factions::Leadership::BaseController
  def destroy
    @faction.delete_all_data!

    redirect_to faction_path(@faction), notice: "All faction data has been deleted. Subscription time has been preserved."
  rescue => e
    Rails.logger.error("Delete faction data failed for faction #{@faction.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_settings_path(@faction), alert: "Failed to delete faction data: #{e.message}"
  end
end
