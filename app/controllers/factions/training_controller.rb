class Factions::TrainingController < ApplicationController
  include FactionAccess
  include FactionHelper

  before_action :require_faction_whitelisted
  before_action :check_tracking_enabled

  SORTABLE_COLUMNS = %w[name xanax_daily energy_refills_daily nerve_refills_daily missions_daily crimes_daily activity_time_daily compliance_score].freeze

  def show
    return if @tracking_disabled

    @earliest_date = PersonalStatSnapshot.tracking_start_date
    @latest_date = PersonalStatSnapshot.tracking_end_date

    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : @earliest_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)

    @total_days_tracked = summary.total_days
    @member_rows = summary.member_rows
    @compliant_members_count = summary.compliant_count
    @warning_members_count = summary.warning_count
    @non_compliant_members_count = summary.non_compliant_count

    # Sorting
    @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "compliance_score"
    @sort_direction = params[:direction] == "asc" ? "asc" : "desc"

    @member_rows = @member_rows.sort_by { |row| row[@sort_column.to_sym] || 0 }
    @member_rows = @member_rows.reverse if @sort_direction == "desc"
  end

  def member
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
