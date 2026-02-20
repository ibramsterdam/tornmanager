class Factions::TrainingController < ApplicationController
  include FactionAccess
  include FactionHelper

  before_action :require_faction_member
  before_action :check_tracking_enabled

  SORTABLE_COLUMNS = %w[name xanax_daily energy_refills_daily nerve_refills_daily missions_daily crimes_daily activity_time_daily compliance_score].freeze

  def show
    return if @tracking_disabled

    # Use tracking constants for date bounds
    @earliest_date = PersonalStatSnapshot.tracking_start_date
    @latest_date = PersonalStatSnapshot.tracking_end_date

    # Parse date parameters
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : @earliest_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    # Calculate total days for the selected range (inclusive)
    @total_days_tracked = (@end_date - @start_date).to_i + 1

    # To calculate stats for days X to Y, we need:
    # - Snapshot from day BEFORE start (X-1) as baseline
    # - Snapshot from end day (Y) as final value
    # The difference gives us what was consumed ON days X through Y
    query_start_date = @start_date - 1.day

    # Build member stats rows
    @member_rows = @faction.users.active.includes(:personal_stat_snapshots).filter_map do |user|
      # Get all snapshots including the day before start
      all_snapshots = user.personal_stat_snapshots
                           .where(date: query_start_date..@end_date)
                           .order(:date)

      # Helper to calculate stat for a specific field
      calculate_stat = lambda do |field|
        snapshots = all_snapshots.where.not(field => nil)
        return { gained: 0, daily: 0.0, days: 0 } if snapshots.size < 2

        first = snapshots.first
        last = snapshots.last
        gained = (last[field] || 0) - (first[field] || 0)

        # Days = the number of days we're measuring consumption FOR
        # If first snapshot is from day X and last is from day Y,
        # we're measuring consumption on days (X+1) through Y
        actual_days = (last.date - first.date).to_i

        daily = actual_days > 0 ? (gained.to_f / actual_days).round(2) : 0.0

        { gained: gained, daily: daily, days: actual_days }
      end

      # Calculate each stat independently
      xanax_stats = calculate_stat.call(:drugs_xanax)
      energy_stats = calculate_stat.call(:other_refills_energy)
      nerve_stats = calculate_stat.call(:other_refills_nerve)
      missions_stats = calculate_stat.call(:missions_contracts_total)
      crimes_stats = calculate_stat.call(:crimes_offenses_total)
      activity_stats = calculate_stat.call(:other_activity_time)

      # Skip if no valid stats for any critical field
      next if xanax_stats[:days].zero? && energy_stats[:days].zero? && nerve_stats[:days].zero?

      # Calculate overall days tracked for this user (max across all stats)
      days_tracked = [
        xanax_stats[:days], energy_stats[:days], nerve_stats[:days],
        missions_stats[:days], crimes_stats[:days], activity_stats[:days]
      ].max

      xanax_daily = xanax_stats[:daily]
      energy_refills_daily = energy_stats[:daily]
      nerve_refills_daily = nerve_stats[:daily]
      missions_daily = missions_stats[:daily]
      crimes_daily = crimes_stats[:daily]
      activity_time_daily = activity_stats[:days] > 0 ? (activity_stats[:gained].to_f / 60 / activity_stats[:days]).round(0) : 0

      # Calculate compliance statuses
      xanax_compliance = stat_compliance(xanax_daily, @faction.xanax_target)
      energy_compliance = stat_compliance(energy_refills_daily, @faction.energy_refill_target)
      nerve_compliance = stat_compliance(nerve_refills_daily, @faction.nerve_refill_target)

      # Calculate overall compliance
      compliance_level = member_compliance_level(xanax_compliance, energy_compliance, nerve_compliance)
      score = compliance_score(xanax_daily, energy_refills_daily, nerve_refills_daily, @faction)

      {
        torn_id: user.torn_id,
        name: user.name,
        compliance_level: compliance_level,
        compliance_score: score,

        xanax_gained: xanax_stats[:gained],
        xanax_daily: xanax_daily,
        xanax_compliance: xanax_compliance,

        energy_refills_gained: energy_stats[:gained],
        energy_refills_daily: energy_refills_daily,
        energy_refills_compliance: energy_compliance,

        nerve_refills_gained: nerve_stats[:gained],
        nerve_refills_daily: nerve_refills_daily,
        nerve_refills_compliance: nerve_compliance,

        missions_gained: missions_stats[:gained],
        missions_daily: missions_daily,

        crimes_gained: crimes_stats[:gained],
        crimes_daily: crimes_daily,

        activity_time_gained: activity_stats[:gained],
        activity_time_daily: activity_time_daily,

        days_tracked: days_tracked
      }
    end

    # Calculate compliance summary counts
    @compliant_members_count = @member_rows.count { |row| row[:compliance_level] == :compliant }
    @warning_members_count = @member_rows.count { |row| row[:compliance_level] == :warning }
    @non_compliant_members_count = @member_rows.count { |row| row[:compliance_level] == :danger }

    # Sorting
    @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "compliance_score"
    @sort_direction = params[:direction] == "asc" ? "asc" : "desc"

    @member_rows = @member_rows.sort_by { |row| row[@sort_column.to_sym] || 0 }
    @member_rows = @member_rows.reverse if @sort_direction == "desc"
  end

  def member
    # Placeholder for Phase 3 - individual member detail page
    redirect_to faction_training_path(@faction), alert: "Member detail page coming soon!"
  end

  helper_method :sort_link

  private

  def check_tracking_enabled
    return if performed?

    unless @faction.track_stats
      @tracking_disabled = true
    end
  end

  def sort_link(column, label)
    direction = (@sort_column == column && @sort_direction == "asc") ? "desc" : "asc"
    { column: column, label: label, direction: direction, current: @sort_column == column, current_direction: @sort_direction }
  end
end
