class Factions::LeadershipController < ApplicationController
  include FactionAccess
  include FactionHelper

  IMPORT_COOLDOWN = 1.minute

  before_action :require_faction_whitelisted, except: [ :setup, :complete_setup, :share_subscription ]
  before_action :require_faction_leader, only: [ :setup, :complete_setup, :update_keys, :delete_torn_key, :delete_tornstats_key, :add_whitelist, :remove_whitelist, :import_spies ]
  before_action :require_faction_whitelisted, only: [ :share_subscription ]
  before_action :require_api_keys_configured, only: [ :show ]
  before_action :check_tracking_enabled

  def show
    return if @tracking_disabled

    load_wars_data
    load_spy_stats_data
    load_settings_data
  end

  def setup
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
  end

  def complete_setup
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    unless new_torn_key.present?
      return redirect_to setup_faction_leadership_path(@faction), alert: "Torn API key is required."
    end

    begin
      key_info = TornApi::Key::Info.new(new_torn_key).fetch

      unless key_info.access.type == "Limited Access"
        return redirect_to setup_faction_leadership_path(@faction),
          alert: "Only Limited Access keys are allowed. Please create a Limited Access key in your Torn settings."
      end

      unless Current.user.admin? || key_info.user.id == Current.user.torn_id
        return redirect_to setup_faction_leadership_path(@faction), alert: "This API key does not belong to you."
      end

      @faction_setting.torn_api_key = new_torn_key
      @faction_setting.torn_api_access_type = key_info.access.type

      if new_tornstats_key.present?
        @faction_setting.tornstats_api_key = new_tornstats_key
      end

      @faction_setting.save!

      redirect_to faction_leadership_path(@faction), notice: "Faction configured successfully! You now have access to war tracking and analytics."
    rescue TornApi::InvalidKeyError
      redirect_to setup_faction_leadership_path(@faction), alert: "Invalid Torn API key."
    rescue TornApi::ApiError => e
      redirect_to setup_faction_leadership_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
    end
  end

  def war_data
    war_data = Rails.cache.read(@faction.war_cache_key)

    if war_data
      render json: war_data
    else
      render json: {}, status: :no_content
    end
  end

  def update_keys
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    changes_made = false

    if new_torn_key
      begin
        key_info = TornApi::Key::Info.new(new_torn_key).fetch

        unless key_info.access.type == "Limited Access"
          return redirect_to faction_leadership_path(@faction, anchor: "settings"),
            alert: "Only Limited Access keys are allowed."
        end

        unless Current.user.admin? || key_info.user.id == Current.user.torn_id
          return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "This API key does not belong to you."
        end

        @faction_setting.torn_api_key = new_torn_key
        @faction_setting.torn_api_access_type = key_info.access.type
        changes_made = true
      rescue TornApi::InvalidKeyError
        return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "Invalid Torn API key."
      rescue TornApi::ApiError => e
        return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "Could not validate Torn API key: #{e.message}"
      end
    end

    if new_tornstats_key
      @faction_setting.tornstats_api_key = new_tornstats_key
      changes_made = true
    end

    if !changes_made
      redirect_to faction_leadership_path(@faction, anchor: "settings"), notice: "No changes made."
    elsif @faction_setting.save
      redirect_to faction_leadership_path(@faction, anchor: "settings"), notice: "API keys saved successfully."
    else
      redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "Failed to save settings."
    end
  end

  def delete_torn_key
    setting = @faction.faction_setting
    if setting
      setting.update!(torn_api_key: nil, torn_api_access_type: nil)
      redirect_to faction_leadership_path(@faction, anchor: "settings"), notice: "Torn API key deleted."
    else
      redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "No API keys configured."
    end
  end

  def delete_tornstats_key
    setting = @faction.faction_setting
    if setting
      setting.update!(tornstats_api_key: nil)
      redirect_to faction_leadership_path(@faction, anchor: "settings"), notice: "TornStats API key deleted."
    else
      redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "No API keys configured."
    end
  end

  def add_whitelist
    user = @faction.users.find_by(id: params[:user_id])

    if user.nil?
      @flash_type = "alert"
      @flash_message = "User not found in this faction."
    elsif @faction.faction_whitelists.exists?(user: user)
      @flash_type = "notice"
      @flash_message = "#{user.name} already has access."
    else
      @faction.faction_whitelists.create!(user: user)
      @flash_type = "notice"
      @flash_message = "#{user.name} has been granted access."
    end

    load_settings_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("whitelist", partial: "factions/leadership/whitelist"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: @flash_type, message: @flash_message })
        ]
      end
      format.html { redirect_to faction_leadership_path(@faction, anchor: "settings"), @flash_type.to_sym => @flash_message }
    end
  end

  def remove_whitelist
    whitelist = @faction.faction_whitelists.find_by(user_id: params[:user_id])

    if whitelist
      name = whitelist.user.name
      whitelist.destroy!
      @flash_type = "notice"
      @flash_message = "#{name}'s access has been removed."
    else
      @flash_type = "alert"
      @flash_message = "User not found in whitelist."
    end

    load_settings_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("whitelist", partial: "factions/leadership/whitelist"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: @flash_type, message: @flash_message })
        ]
      end
      format.html { redirect_to faction_leadership_path(@faction, anchor: "settings"), @flash_type.to_sym => @flash_message }
    end
  end

  def share_subscription
    total_weeks = params[:total_weeks].to_i
    members = @faction.users.active
    member_count = members.count

    if total_weeks <= 0
      return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "Please enter a valid number of weeks to share."
    end

    if member_count == 0
      return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "No faction members found."
    end

    if total_weeks % member_count != 0
      return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "#{total_weeks} weeks cannot be split evenly across #{member_count} members. Try a multiple of #{member_count}."
    end

    weeks_per_member = total_weeks / member_count

    if Current.user.subscription_weeks_remaining < total_weeks
      return redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "You only have #{Current.user.subscription_weeks_remaining} weeks remaining. Cannot share #{total_weeks} weeks."
    end

    ActiveRecord::Base.transaction do
      Current.user.deduct_subscription!(total_weeks)

      grant = FactionSubscriptionGrant.create!(
        torn_faction_id: @faction.torn_id,
        faction: @faction,
        faction_name: @faction.name,
        weeks_granted: total_weeks,
        granted_by: Current.user,
        granted_at: Time.current
      )

      members.each do |member|
        SubscriptionGrant.create!(
          faction_subscription_grant: grant,
          user: member
        )
        member.extend_subscription!(weeks_per_member)
      end
    end

    redirect_to faction_leadership_path(@faction, anchor: "settings"), notice: "Shared #{total_weeks} weeks across #{member_count} members (#{weeks_per_member} weeks each)."
  rescue => e
    Rails.logger.error("Share subscription failed for user #{Current.user.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_path(@faction, anchor: "settings"), alert: "Failed to share subscription: #{e.message}"
  end

  def import_spies
    target_faction_id = params[:target_faction_id].to_s.strip

    if target_faction_id.blank?
      return redirect_to faction_leadership_path(@faction, anchor: "spies"), alert: "Please enter a faction ID to import spy data for."
    end

    @faction_setting = @faction.faction_setting
    unless @faction_setting&.tornstats_api_key?
      return redirect_to faction_leadership_path(@faction, anchor: "spies"), alert: "TornStats API key must be configured before importing spy data."
    end

    if rate_limited?
      return redirect_to faction_leadership_path(@faction, anchor: "spies"), alert: "Import was run recently. Try again in #{seconds_until_import} seconds."
    end

    Rails.cache.write(import_cache_key, Time.current, expires_in: IMPORT_COOLDOWN)

    begin
      spies = TornStatsApi::SpyFaction.new(
        @faction_setting.tornstats_api_key,
        faction_id: target_faction_id
      ).fetch

      imported = 0
      spies.each do |spy|
        import_spy_report(spy)
        imported += 1
      end

      Rails.cache.delete(@faction.war_cache_key)

      redirect_to faction_leadership_path(@faction, anchor: "spies"), notice: "Successfully imported #{imported} spy reports."
    rescue TornStatsApi::NotFoundError => e
      redirect_to faction_leadership_path(@faction, anchor: "spies"), alert: "No spy data found: #{e.message}"
    rescue TornStatsApi::InvalidKeyError => e
      redirect_to faction_leadership_path(@faction, anchor: "spies"), alert: "Invalid TornStats API key: #{e.message}"
    rescue TornStatsApi::ApiError => e
      Rails.logger.error("TornStats import failed: #{e.class} - #{e.message}")
      redirect_to faction_leadership_path(@faction, anchor: "spies"), alert: "Import failed: #{e.message}"
    end
  end

  private

  def check_tracking_enabled
    return if performed?

    unless @faction.track_stats
      @tracking_disabled = true
    end
  end

  def require_api_keys_configured
    return if performed?
    find_faction unless @faction
    return if performed?
    return if @faction.faction_setting&.torn_api_key?

    redirect_to setup_faction_leadership_path(@faction)
  end

  def load_wars_data
    refresh_latest_wars

    @wars = @faction.ranked_wars.recent.includes(:faction)

    completed_wars = @wars.completed
    @wins = completed_wars.won.count
    @losses = completed_wars.lost.count

    @ongoing_war = @wars.ongoing.select(&:in_progress?).first
    @scheduled_war = @wars.ongoing.select(&:scheduled?).first

    @member_performance = calculate_member_performance(completed_wars)
  end

  def load_spy_stats_data
    @spy_reports = @faction.spy_reports.order(total: :desc)
    @spy_report_count = @spy_reports.count
    @last_import_at = Rails.cache.read(import_cache_key)
    @can_import = @last_import_at.nil?
    @seconds_until_import = seconds_until_import
  end

  def load_settings_data
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
    @torn_api_key_masked = mask_key(@faction_setting.torn_api_key)
    @tornstats_api_key_masked = mask_key(@faction_setting.tornstats_api_key)
    @whitelisted_users = @faction.whitelisted_users.order(:name)
    @faction_members = @faction.users.active.where.not(id: @whitelisted_users.select(:id)).order(:name)
    @subscription_weeks_remaining = Current.user.subscription_weeks_remaining
    @faction_member_count = @faction.users.active.count
    @war_polling_active = @faction.war_polling_active?
  end

  def refresh_latest_wars
    api_key = @faction.faction_setting&.torn_api_key
    return unless api_key.present?

    wars = TornApi::Faction::RankedWars.new(api_key, @faction.torn_id).fetch(limit: 5)
    return if wars.empty?

    wars.each do |war_data|
      our_faction_data = war_data["factions"].find { |f| f["id"] == @faction.torn_id }
      their_faction_data = war_data["factions"].find { |f| f["id"] != @faction.torn_id }
      next unless our_faction_data && their_faction_data

      ranked_war = @faction.ranked_wars.find_or_initialize_by(torn_war_id: war_data["id"])

      ranked_war.assign_attributes(
        opponent_faction_id: their_faction_data["id"],
        opponent_faction_name: their_faction_data["name"],
        started_at: Time.at(war_data["start"]),
        ended_at: war_data["end"].to_i > 0 ? Time.at(war_data["end"]) : nil,
        target_score: war_data["target"],
        our_score: our_faction_data["score"],
        their_score: their_faction_data["score"],
        winner_faction_id: war_data["winner"]
      )

      ranked_war.save!
    end
  rescue TornApi::ApiError => e
    Rails.logger.warn("[LeadershipController] Failed to refresh latest wars: #{e.message}")
  end

  def calculate_member_performance(wars)
    return [] if wars.empty?

    performance = {}

    wars.each do |war|
      next unless war.our_members.present?

      war.our_members.each do |member|
        torn_id = member["id"].to_s
        name = member["name"]

        performance[torn_id] ||= {
          name: name,
          torn_id: torn_id,
          wars_participated: 0,
          total_attacks: 0,
          total_score: 0.0
        }

        attacks = member["attacks"].to_i
        if attacks > 0
          performance[torn_id][:wars_participated] += 1
          performance[torn_id][:total_attacks] += attacks
          performance[torn_id][:total_score] += member["score"].to_f
        end
      end
    end

    performance.values.map do |p|
      p[:avg_attacks] = p[:wars_participated] > 0 ? (p[:total_attacks].to_f / p[:wars_participated]).round(1) : 0
      p[:avg_score] = p[:wars_participated] > 0 ? (p[:total_score] / p[:wars_participated]).round(1) : 0
      p[:avg_respect_per_hit] = p[:total_attacks] > 0 ? (p[:total_score] / p[:total_attacks]).round(2) : 0
      p
    end.sort_by { |p| -p[:total_score] }
  end

  def import_cache_key
    "faction:#{@faction.id}:spy_import:last_run"
  end

  def rate_limited?
    Rails.cache.exist?(import_cache_key)
  end

  def seconds_until_import
    last_run = Rails.cache.read(import_cache_key)
    return 0 unless last_run

    remaining = IMPORT_COOLDOWN - (Time.current - last_run)
    [ remaining.to_i, 0 ].max
  end

  def import_spy_report(spy)
    report = @faction.spy_reports.find_or_initialize_by(torn_id: spy.torn_id)
    report.assign_attributes(
      strength: spy.strength,
      defense: spy.defense,
      speed: spy.speed,
      dexterity: spy.dexterity,
      total: spy.total,
      spied_at: spy.spied_at
    )
    report.save!
  end

  def mask_key(key)
    return nil if key.blank?
    "#{key[0..3]}********#{key[-4..]}"
  end
end
