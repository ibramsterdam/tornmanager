class HallOfFamersController < ApplicationController
  allow_unauthenticated_access

  SORTABLE_COLUMNS = %w[name xanax_taken stat_enhancers_taken energy_drinks_used networth daily_se_average].freeze

  def index
    @table_rows = TornUser.hof_stats_users.includes(:personal_stat_snapshots).map do |torn_user|
      snapshots = torn_user.personal_stat_snapshots.order(:created_at)
      latest = snapshots.last
      first = snapshots.first

      if latest && first && snapshots.size > 1
        days_tracked = (latest.created_at.to_date - first.created_at.to_date).to_i
        se_gained = (latest.items_used_stat_enhancers || 0) - (first.items_used_stat_enhancers || 0)
        daily_se_average = days_tracked > 0 ? (se_gained.to_f / days_tracked).round(2) : 0
      else
        daily_se_average = 0
      end

      {
        name: torn_user.name,
        torn_id: torn_user.torn_id,
        xanax_taken: latest&.drugs_xanax || 0,
        stat_enhancers_taken: latest&.items_used_stat_enhancers || 0,
        energy_drinks_used: latest&.items_used_energy_drinks || 0,
        networth: latest&.networth_total || 0,
        daily_se_average: daily_se_average
      }
    end

    @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "stat_enhancers_taken"
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
