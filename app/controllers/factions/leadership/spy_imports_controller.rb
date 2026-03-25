class Factions::Leadership::SpyImportsController < Factions::Leadership::BaseController
  def create
    target_faction_id = params[:target_faction_id].to_s.strip

    if target_faction_id.blank?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "Please enter a faction ID to import spy data for."
    end

    unless @faction.tornstats_api_key&.key.present?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "TornStats API key must be configured before importing spy data."
    end

    if rate_limited?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "Import was run recently. Try again in #{seconds_until_import} seconds."
    end

    Rails.cache.write(import_cache_key, Time.current, expires_in: IMPORT_COOLDOWN)

    begin
      spies = TornStatsApi::SpyFaction.new(
        @faction.tornstats_api_key.key,
        faction_id: target_faction_id
      ).fetch

      imported = 0
      spies.each do |spy|
        @faction.import_spy_report(spy)
        imported += 1
      end

      Rails.cache.delete(@faction.war_cache_key)

      redirect_to faction_leadership_spy_reports_path(@faction), notice: "Successfully imported #{imported} spy reports."
    rescue TornStatsApi::NotFoundError => e
      redirect_to faction_leadership_spy_reports_path(@faction), alert: "No spy data found: #{e.message}"
    rescue TornStatsApi::InvalidKeyError => e
      redirect_to faction_leadership_spy_reports_path(@faction), alert: "Invalid TornStats API key: #{e.message}"
    rescue TornStatsApi::ApiError => e
      Rails.logger.error("TornStats import failed: #{e.class} - #{e.message}")
      redirect_to faction_leadership_spy_reports_path(@faction), alert: "Import failed: #{e.message}"
    end
  end
end
