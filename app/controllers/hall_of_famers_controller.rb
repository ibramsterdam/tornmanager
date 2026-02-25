class HallOfFamersController < ApplicationController
  HOF_OWNER_TORN_ID = 2685512
  SORTABLE_COLUMNS = %w[name xanax_gained energy_drinks_gained networth_gained total_se se_gained].freeze

  before_action :require_hof_access

  def index
    @earliest_date = PersonalStatSnapshot.tracking_start_date
    @latest_date = PersonalStatSnapshot.tracking_end_date

    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : @earliest_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    @total_days_tracked = (@end_date - @start_date).to_i + 1

    query_start_date = @start_date - 1.day

    @table_rows = User.hof_stats_users.includes(:personal_stat_snapshots).filter_map do |user|
      snapshots = user.personal_stat_snapshots
                      .where(date: query_start_date..@end_date)
                      .order(:date)

      next if snapshots.size < 2

      first = snapshots.first
      latest = snapshots.last
      actual_days = (latest.date - first.date).to_i

      xanax_gained = (latest.drugs_xanax || 0) - (first.drugs_xanax || 0)
      energy_drinks_gained = (latest.items_used_energy_drinks || 0) - (first.items_used_energy_drinks || 0)
      se_gained = (latest.items_used_stat_enhancers || 0) - (first.items_used_stat_enhancers || 0)
      networth_gained = (latest.networth_total || 0) - (first.networth_total || 0)

      xanax_daily = actual_days > 0 ? (xanax_gained.to_f / actual_days).round(2) : 0
      energy_drinks_daily = actual_days > 0 ? (energy_drinks_gained.to_f / actual_days).round(2) : 0
      se_daily = actual_days > 0 ? (se_gained.to_f / actual_days).round(2) : 0
      networth_daily = actual_days > 0 ? (networth_gained.to_f / actual_days).round(0) : 0

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
        se_daily: se_daily,
        days_tracked: actual_days
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

  def require_hof_access
    redirect_to root_path, alert: "Access denied." unless Current.user&.admin? || Current.user&.torn_id == HOF_OWNER_TORN_ID
  end
end
