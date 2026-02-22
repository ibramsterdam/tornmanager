class Factions::SpyStatsController < ApplicationController
  include FactionAccess

  before_action :require_faction_whitelisted
  before_action :require_spy_keys_configured

  def show
    @spy_reports = @faction.spy_reports.order(total: :desc)
    @total_count = @spy_reports.count
  end

  private

  def require_spy_keys_configured
    setting = @faction.faction_setting
    return if setting&.keys_configured?

    redirect_to faction_settings_path(@faction),
      alert: "API keys must be configured before viewing spy stats."
  end
end
