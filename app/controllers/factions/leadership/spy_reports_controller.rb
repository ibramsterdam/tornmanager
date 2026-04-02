class Factions::Leadership::SpyReportsController < Factions::Leadership::BaseController
  def show
    load_spy_stats_data
    load_settings_data
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

  private

  def spy_report_params
    params.require(:spy_report).permit(:strength, :defense, :speed, :dexterity)
  end
end
