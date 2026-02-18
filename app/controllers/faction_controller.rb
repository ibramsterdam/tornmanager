class FactionController < ApplicationController
  include FactionHelper

  SORTABLE_COLUMNS = %w[name xanax_daily energy_refills_daily nerve_refills_daily missions_daily crimes_daily activity_time_daily compliance_score].freeze

  def index
    # Allow admins to view any faction via faction_id parameter
    if Current.user.admin?
      if params[:faction_id].present?
        @faction = Faction.find_by(id: params[:faction_id])
        unless @faction
          redirect_to admin_dashboard_path, alert: "Faction not found."
          return
        end
      else
        # Admin with no faction_id - pick first tracked faction
        @faction = Faction.where(track_stats: true).order(:name).first
        unless @faction
          redirect_to admin_dashboard_path, alert: "No factions with tracking enabled."
          return
        end
      end
    else
      # Regular users view their own faction
      unless Current.user.faction
        @no_faction = true
        return
      end
      @faction = Current.user.faction
    end

    # Check if faction has tracking enabled
    unless @faction.track_stats
      @tracking_disabled = true
      return
    end

    # Use tracking constants for date bounds
    @earliest_date = PersonalStatSnapshot.tracking_start_date
    @latest_date = PersonalStatSnapshot.tracking_end_date

    # Parse date parameters
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : @earliest_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    # Calculate total days for the selected range
    @total_days_tracked = (@end_date - @start_date).to_i + 1

    # Build member stats rows
    # Convert date range to timestamp range for querying
    start_timestamp = @start_date.beginning_of_day.to_i
    end_timestamp = @end_date.end_of_day.to_i

    @member_rows = @faction.users.active.includes(:personal_stat_snapshots).filter_map do |user|
      # Get all snapshots in date range
      all_snapshots = user.personal_stat_snapshots
                           .where(timestamp: start_timestamp..end_timestamp)
                           .order(:timestamp)

      # Helper to calculate stat for a specific field
      calculate_stat = lambda do |field|
        snapshots = all_snapshots.where.not(field => nil)
        return { gained: 0, daily: 0.0, days: 0 } if snapshots.size < 2

        first = snapshots.first
        last = snapshots.last
        gained = (last[field] || 0) - (first[field] || 0)
        daily = @total_days_tracked > 0 ? (gained.to_f / @total_days_tracked).round(2) : 0.0

        { gained: gained, daily: daily, days: @total_days_tracked }
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
        activity_time_daily: activity_time_daily
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
