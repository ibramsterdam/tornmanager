class Factions::SpyStatsController < ApplicationController
  include FactionAccess

  before_action :require_faction_whitelisted

  def show
    @spy_reports = @faction.spy_reports.order(total: :desc)
    @total_count = @spy_reports.count
  end
end
