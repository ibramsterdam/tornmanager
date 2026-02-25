class FactionsController < ApplicationController
  include FactionAccess
  include FactionHelper

  SORTABLE_COLUMNS = %w[name xanax_daily energy_refills_daily nerve_refills_daily missions_daily crimes_daily activity_time_daily compliance_score].freeze

  before_action :require_faction_member, only: [ :show, :war_data ]

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

    load_hero_data
    load_training_data
    load_war_data
  end

  def war_data
    war_data = Rails.cache.read(@faction.war_cache_key)

    if war_data
      render json: war_data
    else
      render json: {}, status: :no_content
    end
  end

  helper_method :sort_link

  private

  def load_hero_data
    # Member count
    @member_count = @faction.users.active.count

    # War record
    completed_wars = @faction.ranked_wars.completed
    @war_wins = completed_wars.won.count
    @war_losses = completed_wars.lost.count

    # Weekly top performers (last calendar week: Monday to Sunday)
    last_week_end = Date.current.beginning_of_week(:monday) - 1.day
    last_week_start = last_week_end.beginning_of_week(:monday)
    weekly_summary = ComplianceSummary.new(@faction, start_date: last_week_start, end_date: last_week_end)
    @weekly_top_performers = weekly_summary.member_rows
                                           .sort_by { |row| -row[:xanax_daily] }
                                           .first(10)
    @week_start = last_week_start
    @week_end = last_week_end
  end

  def load_training_data
    @earliest_date = PersonalStatSnapshot.tracking_start_date
    @latest_date = PersonalStatSnapshot.tracking_end_date

    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : @earliest_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @latest_date

    @backfilling_members = @faction.users.where("backfill_ends_at > ?", Time.current)

    summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)

    @total_days_tracked = summary.total_days
    @member_rows = summary.member_rows
    @compliant_members_count = summary.compliant_count
    @warning_members_count = summary.warning_count
    @non_compliant_members_count = summary.non_compliant_count

    @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "compliance_score"
    @sort_direction = params[:direction] == "asc" ? "asc" : "desc"

    @member_rows = @member_rows.sort_by { |row| row[@sort_column.to_sym] || 0 }
    @member_rows = @member_rows.reverse if @sort_direction == "desc"

    @xanax_target = @faction.xanax_target
    @energy_target = @faction.energy_refill_target
    @nerve_target = @faction.nerve_refill_target
  end

  def load_war_data
    @current_war = @faction.current_war
    @latest_war = @faction.ranked_wars.completed.recent.first unless @current_war
    @api_keys_configured = @faction.faction_setting&.torn_api_key.present?

    return unless @current_war && @api_keys_configured

    refresh_current_war_scores
    ensure_war_polling_active

    @war_data = Rails.cache.read(@faction.war_cache_key)
  end

  def ensure_war_polling_active
    return unless @faction.faction_setting&.torn_api_key?

    if @faction.war_polling_active?
      unless Rails.cache.exist?(@faction.war_cache_key)
        Rails.logger.info("Restarting dead war polling for faction #{@faction.torn_id}")
        @faction.start_war_polling!
      end
    else
      @faction.start_war_polling!
    end
  end

  def refresh_current_war_scores
    api_key = @faction.faction_setting&.torn_api_key
    return unless api_key.present?

    wars = TornApi::Faction::RankedWars.new(api_key, @faction.torn_id).fetch(limit: 1)
    war_data = wars.find { |w| w["id"] == @current_war.torn_war_id }
    return unless war_data

    our_faction_data = war_data["factions"].find { |f| f["id"] == @faction.torn_id }
    their_faction_data = war_data["factions"].find { |f| f["id"] != @faction.torn_id }
    return unless our_faction_data && their_faction_data

    @current_war.update!(
      our_score: our_faction_data["score"],
      their_score: their_faction_data["score"],
      ended_at: war_data["end"].to_i > 0 ? Time.at(war_data["end"]) : nil,
      winner_faction_id: war_data["winner"]
    )
  rescue TornApi::ApiError, TornApi::InvalidKeyError => e
    Rails.logger.warn("Failed to refresh war scores for faction #{@faction.torn_id}: #{e.message}")
  end

  def sort_link(column, label)
    direction = (@sort_column == column && @sort_direction == "asc") ? "desc" : "asc"
    { column: column, label: label, direction: direction, current: @sort_column == column, current_direction: @sort_direction }
  end
end
