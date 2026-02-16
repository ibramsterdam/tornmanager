class FactionController < ApplicationController
  include FactionHelper

  SORTABLE_COLUMNS = %w[name xanax_daily energy_refills_daily nerve_refills_daily merits_daily missions_daily boosters_daily activity_time_daily compliance_score].freeze

  def index
    # Check if user has a faction
    unless Current.user.faction
      @no_faction = true
      return
    end

    @faction = Current.user.faction

    # Check if faction has tracking enabled
    unless @faction.track_stats
      @tracking_disabled = true
      return
    end

    # Determine date range for filtering
    all_snapshots = PersonalStatSnapshot.joins(:user)
                                       .where(users: { faction_id: @faction.id })
                                       .order(:created_at)

    @earliest_date = all_snapshots.first&.created_at&.to_date
    @latest_date = all_snapshots.last&.created_at&.to_date

    # If no snapshots exist, set defaults
    if @earliest_date.nil? || @latest_date.nil?
      @start_date = Date.today
      @end_date = Date.today
      @total_days_tracked = 0
      @member_rows = []
      @compliant_members_count = 0
      @warning_members_count = 0
      @non_compliant_members_count = 0
      return
    end

    # Parse date parameters (default to last 30 days)
    default_start = [ @earliest_date, 30.days.ago.to_date ].max
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : default_start
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    # Calculate total days for the selected range
    @total_days_tracked = (@end_date - @start_date).to_i + 1

    # Build member stats rows
    @member_rows = @faction.users.includes(:personal_stat_snapshots).filter_map do |user|
      # Filter snapshots by date range
      snapshots = user.personal_stat_snapshots
                           .where("DATE(created_at) >= ? AND DATE(created_at) <= ?", @start_date, @end_date)
                           .order(:created_at)

      # Skip users with no snapshots or only one snapshot
      next if snapshots.empty? || snapshots.size < 2

      latest = snapshots.last
      first = snapshots.first

      # Calculate days between first and last snapshot (inclusive)
      actual_days = (latest.created_at.to_date - first.created_at.to_date).to_i
      next if actual_days.zero?

      # Calculate gains
      xanax_gained = (latest.drugs_xanax || 0) - (first.drugs_xanax || 0)
      energy_refills_gained = (latest.other_refills_energy || 0) - (first.other_refills_energy || 0)
      nerve_refills_gained = (latest.other_refills_nerve || 0) - (first.other_refills_nerve || 0)
      merits_gained = (latest.other_merits_bought || 0) - (first.other_merits_bought || 0)
      missions_gained = (latest.missions_missions || 0) - (first.missions_missions || 0)
      boosters_gained = (latest.items_used_boosters || 0) - (first.items_used_boosters || 0)
      activity_time_gained = (latest.other_activity_time || 0) - (first.other_activity_time || 0)

      # Calculate daily averages using actual snapshot days
      xanax_daily = (xanax_gained.to_f / actual_days).round(2)
      energy_refills_daily = (energy_refills_gained.to_f / actual_days).round(2)
      nerve_refills_daily = (nerve_refills_gained.to_f / actual_days).round(2)
      merits_daily = (merits_gained.to_f / actual_days).round(2)
      missions_daily = (missions_gained.to_f / actual_days).round(2)
      boosters_daily = (boosters_gained.to_f / actual_days).round(2)
      activity_time_daily = (activity_time_gained.to_f / actual_days).round(0)  # minutes per day

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

        xanax_gained: xanax_gained,
        xanax_daily: xanax_daily,
        xanax_compliance: xanax_compliance,

        energy_refills_gained: energy_refills_gained,
        energy_refills_daily: energy_refills_daily,
        energy_refills_compliance: energy_compliance,

        nerve_refills_gained: nerve_refills_gained,
        nerve_refills_daily: nerve_refills_daily,
        nerve_refills_compliance: nerve_compliance,

        merits_gained: merits_gained,
        merits_daily: merits_daily,

        missions_gained: missions_gained,
        missions_daily: missions_daily,

        boosters_gained: boosters_gained,
        boosters_daily: boosters_daily,

        activity_time_gained: activity_time_gained,
        activity_time_daily: activity_time_daily,

        actual_days: actual_days  # Store for debugging/display
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
    redirect_to faction_index_path, alert: "Member detail page coming soon!"
  end

  helper_method :sort_link

  private

  def sort_link(column, label)
    direction = (@sort_column == column && @sort_direction == "asc") ? "desc" : "asc"
    { column: column, label: label, direction: direction, current: @sort_column == column, current_direction: @sort_direction }
  end
end
