class FactionsController < ApplicationController
  include FactionAccess

  before_action :require_faction_whitelisted, only: [ :show ]

  def index
    if Current.user.faction.present?
      redirect_to faction_path(Current.user.faction)
    else
      redirect_to root_path, alert: "You are not a member of any faction."
    end
  end

  def show
    unless @faction.track_stats
      @tracking_disabled = true
      return
    end

    summary = ComplianceSummary.new(@faction)

    @total_members = summary.member_rows.size
    @compliant_count = summary.compliant_count
    @warning_count = summary.warning_count
    @non_compliant_count = summary.non_compliant_count
    @worst_performers = summary.worst_performers(5)

    @xanax_target = @faction.xanax_target
    @energy_target = @faction.energy_refill_target
    @nerve_target = @faction.nerve_refill_target
  end
end
