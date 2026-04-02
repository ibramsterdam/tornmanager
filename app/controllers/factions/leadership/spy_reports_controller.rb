class Factions::Leadership::SpyReportsController < Factions::Leadership::BaseController
  def show
    unless @faction.tornstats_api_key.present?
      return redirect_to faction_leadership_path(@faction), alert: "Configure your TornStats API key in Settings to access spy reports."
    end

    load_spy_stats_data
    load_settings_data
    @current_war = @faction.current_war
  end

  def update
    report = @faction.spy_reports.find(params[:id])
    report.update!(spy_report_params)

    render json: { success: true }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def destroy
    report = @faction.spy_reports.find(params[:id])
    report.destroy!

    redirect_to faction_leadership_spy_reports_path(@faction), notice: "Spy report deleted."
  end

  def fetch_enemy
    war = @faction.current_war
    unless war
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "No active war found."
    end

    unless @faction.tornstats_api_key&.key.present?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "TornStats API key must be configured."
    end

    spies = TornStatsApi::SpyFaction.new(
      @faction.tornstats_api_key.key,
      faction_id: war.opponent_faction_id
    ).fetch

    imported = 0
    spies.each do |spy|
      @faction.import_spy_report(spy)
      imported += 1
    end

    Rails.cache.delete(@faction.war_cache_key)

    redirect_to faction_leadership_spy_reports_path(@faction), notice: "Successfully imported #{imported} spy reports for #{war.opponent_faction_name}."
  rescue TornStatsApi::NotFoundError => e
    redirect_to faction_leadership_spy_reports_path(@faction), alert: "No spy data found: #{e.message}"
  rescue TornStatsApi::InvalidKeyError => e
    redirect_to faction_leadership_spy_reports_path(@faction), alert: "Invalid TornStats API key: #{e.message}"
  rescue TornStatsApi::ApiError => e
    redirect_to faction_leadership_spy_reports_path(@faction), alert: "Import failed: #{e.message}"
  end

  private

  def spy_report_params
    params.require(:spy_report).permit(:strength, :defense, :speed, :dexterity)
  end
end
