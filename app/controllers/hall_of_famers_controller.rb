class HallOfFamersController < ApplicationController
  SORTABLE_COLUMNS = %w[name xanax_gained energy_drinks_gained networth_gained total_se se_gained].freeze

  def index
    # Use tracking constants for date range
    @earliest_date = PersonalStatSnapshot.tracking_start_date
    @latest_date = PersonalStatSnapshot.tracking_end_date

    # Parse date parameters
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : @earliest_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    # Calculate total days for the selected range
    @total_days_tracked = (@end_date - @start_date).to_i

    @table_rows = User.hof_stats_users.includes(:personal_stat_snapshots).filter_map do |user|
      # Filter snapshots by date range
      snapshots = user.personal_stat_snapshots
                      .where(date: @start_date..@end_date)
                      .order(:date)

      # Skip users with no snapshots
      next if snapshots.empty?

      latest = snapshots.last
      first = snapshots.first

      if latest && first && snapshots.size > 1
        # Calculate gains
        xanax_gained = (latest.drugs_xanax || 0) - (first.drugs_xanax || 0)
        energy_drinks_gained = (latest.items_used_energy_drinks || 0) - (first.items_used_energy_drinks || 0)
        se_gained = (latest.items_used_stat_enhancers || 0) - (first.items_used_stat_enhancers || 0)
        networth_gained = (latest.networth_total || 0) - (first.networth_total || 0)

        # Calculate daily averages using the overall tracking period
        xanax_daily = @total_days_tracked > 0 ? (xanax_gained.to_f / @total_days_tracked).round(2) : 0
        energy_drinks_daily = @total_days_tracked > 0 ? (energy_drinks_gained.to_f / @total_days_tracked).round(2) : 0
        se_daily = @total_days_tracked > 0 ? (se_gained.to_f / @total_days_tracked).round(2) : 0
        networth_daily = @total_days_tracked > 0 ? (networth_gained.to_f / @total_days_tracked).round(0) : 0
      else
        xanax_gained = energy_drinks_gained = se_gained = networth_gained = 0
        xanax_daily = energy_drinks_daily = se_daily = networth_daily = 0
      end

      {
        name: user.name,
        torn_id: user.torn_id,
        xanax_gained: xanax_gained,
        xanax_daily: xanax_daily,
        energy_drinks_gained: energy_drinks_gained,
        energy_drinks_daily: energy_drinks_daily,
        networth_gained: networth_gained,
        networth_daily: networth_daily,
        total_se: latest&.items_used_stat_enhancers || 0,
        se_gained: se_gained,
        se_daily: se_daily
      }
    end

    @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "se_gained"
    @sort_direction = params[:direction] == "asc" ? "asc" : "desc"

    @table_rows = @table_rows.sort_by { |row| row[@sort_column.to_sym] || 0 }
    @table_rows = @table_rows.reverse if @sort_direction == "desc"
  end

  helper_method :sort_link

  private

  def sort_link(column, label)
    direction = (@sort_column == column && @sort_direction == "asc") ? "desc" : "asc"
    { column: column, label: label, direction: direction, current: @sort_column == column, current_direction: @sort_direction }
  end
end
