class FactionsController < ApplicationController
  include FactionAccess
  include FactionHelper

  SORTABLE_COLUMNS = %w[name xanax_daily energy_refills_daily nerve_refills_daily missions_daily crimes_daily activity_time_daily compliance_score].freeze

  before_action :require_faction_member, only: [ :war_data ]
  before_action :find_faction_and_check_access, only: [ :show ]
  before_action :require_setup_completed, only: [ :show ]
  before_action :find_faction_for_setup, only: [ :setup, :create, :setup_unavailable ]
  before_action :require_faction_leader_for_setup, only: [ :setup, :create ]

  def index
    if Current.user.faction.present?
      redirect_to faction_path(Current.user.faction)
    else
      redirect_to stocks_path
    end
  end

  def show
    unless Current.user.subscribed? || Current.user.admin?
      return render :subscription_expired
    end

    load_hero_data
    load_training_data
    load_war_data
    load_data_coverage
  end

  def setup
    @api_key_prefill = Current.user.has_limited_access? ? Current.user.api_key : nil
  end

  def setup_unavailable
  end

  MAX_FACTIONS = 15

  def create
    if Faction.where(setup_completed: true).count >= MAX_FACTIONS
      flash.now[:alert] = "Maximum number of factions (#{MAX_FACTIONS}) has been reached. Join our Discord from the menu and mention it in #support."
      return render :setup, status: :unprocessable_entity
    end

    api_key = params[:api_key].to_s.strip

    begin
      key_info = TornApi::Key::Info.new(api_key).fetch
    rescue TornApi::InvalidKeyError
      flash.now[:alert] = "Invalid API key. Please check and try again."
      return render :setup, status: :unprocessable_entity
    end

    unless key_info.access.type == "Limited Access"
      flash.now[:alert] = "This key is #{key_info.access.type}. A Limited Access key is required."
      return render :setup, status: :unprocessable_entity
    end

    unless key_info.access.faction == true
      flash.now[:alert] = "This API key does not have faction access. Please enable faction access in your Torn API key settings."
      return render :setup, status: :unprocessable_entity
    end

    unless key_info.user.id == Current.user.torn_id
      flash.now[:alert] = "This API key does not belong to you."
      return render :setup, status: :unprocessable_entity
    end

    unless key_info.user.faction_id == @faction.torn_id
      flash.now[:alert] = "This API key is for a different faction."
      return render :setup, status: :unprocessable_entity
    end

    @faction.create_faction_setting! unless @faction.faction_setting
    torn_record = @faction.torn_api_key || @faction.build_torn_api_key
    torn_record.update!(key: api_key, access_type: "Limited Access", faction_access: key_info.access.faction == true)

    Current.user.update!(leadership_access: true)

    members = TornApi::Faction::Members.new(api_key, @faction.torn_id).fetch

    # Create a faction-level subscription (1 month trial)
    @faction.create_subscription!(expires_at: 1.month.from_now) unless @faction.subscription

    members.each do |member|
      user = User.find_by(torn_id: member.id)
      next unless user

      attrs = { position: member.position }
      attrs[:leadership_access] = true if %w[Leader Co-leader].include?(member.position)
      user.update!(attrs)
    end

    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = Date.yesterday
    dates_count = (start_date..end_date).count
    members_count = @faction.users.active.count
    total_api_calls = members_count * dates_count * 2 # 2 batches per user per date
    estimated_seconds = [ total_api_calls * BackfillPersonalStatsJob::SECONDS_PER_API_CALL, 1 ].max.to_i

    @faction.update!(
      backfill_ends_at: Time.current + estimated_seconds.seconds,
      backfill_target_date: start_date
    )

    BackfillRankedWarsJob.perform_later(@faction.id)
    BackfillPersonalStatsJob.perform_later(
      @faction.id,
      start_date.to_s,
      end_date.to_s
    )

    @faction.update!(setup_completed: true)

    redirect_to faction_path(@faction), notice: "Your faction has been set up. Welcome to TornManager!"
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

  def find_faction_and_check_access
    find_faction
    return if performed?

    unless Current.user.admin? || Current.user.faction == @faction
      redirect_to root_path, alert: "You don't have access to this faction."
    end
  end

  def require_faction_leader_for_setup
    return if performed?
    return if Current.user.admin? || Current.user.faction_leader?

    redirect_to setup_unavailable_faction_path(@faction)
  end

  def find_faction_for_setup
    torn_id = params[:torn_id]
    @faction = Faction.find_by(torn_id: torn_id)

    unless @faction
      redirect_to root_path, alert: "Faction not found."
      return
    end

    unless Current.user.faction == @faction
      redirect_to root_path, alert: "You cannot set up this faction."
      return
    end

    if @faction.setup_completed?
      redirect_to root_path, alert: "This faction is already set up."
    end
  end

  def load_hero_data
    @member_count = @faction.users.active.count

    current_year_wars = @faction.ranked_wars.completed.where(started_at: Date.current.beginning_of_year..)
    @war_wins = current_year_wars.won.count
    @war_losses = current_year_wars.lost.count

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
    @api_keys_configured = @faction.torn_api_key.present?

    return unless @current_war && @api_keys_configured

    ensure_war_polling_active

    @war_data = Rails.cache.read(@faction.war_cache_key)
  end

  def ensure_war_polling_active
    return unless @faction.torn_api_key.present?
    return if @faction.war_polling_active?

    @faction.start_war_polling!
  end

  def load_data_coverage
    faction_user_ids = @faction.users.active.pluck(:id)

    if faction_user_ids.empty?
      @data_coverage_rate = 100.0
      return
    end

    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date
    expected_days = (start_date..end_date).count

    total_expected = faction_user_ids.size * expected_days
    total_existing = PersonalStatSnapshot
      .where(user_id: faction_user_ids)
      .where(date: start_date..end_date)
      .count

    @data_coverage_rate = total_expected > 0 ? (total_existing.to_f / total_expected * 100).round(1) : 100.0
    @data_total_missing_days = total_expected - total_existing
  end

  def sort_link(column, label)
    direction = (@sort_column == column && @sort_direction == "asc") ? "desc" : "asc"
    { column: column, label: label, direction: direction, current: @sort_column == column, current_direction: @sort_direction }
  end
end
