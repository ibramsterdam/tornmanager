class Factions::RankedWarsController < ApplicationController
  include FactionAccess

  SYNC_COOLDOWN = 1.minute

  before_action :require_faction_whitelisted
  before_action :check_tracking_enabled

  def index
    return if @tracking_disabled

    # Sync cooldown
    @can_sync = can_sync?
    @seconds_until_sync = seconds_until_sync

    # Fetch ranked wars
    @wars = @faction.ranked_wars.recent.includes(:faction)

    # Summary stats (only completed wars)
    completed_wars = @wars.completed
    @wins = completed_wars.won.count
    @losses = completed_wars.lost.count

    # Ongoing war (in progress)
    @ongoing_war = @wars.ongoing.select(&:in_progress?).first

    # Calculate member performance across all wars
    @member_performance = calculate_member_performance(completed_wars)
  end

  def show
    @war = @faction.ranked_wars.find_by(torn_war_id: params[:id])

    unless @war
      redirect_to faction_ranked_wars_path(@faction), alert: "War not found."
      return
    end

    if @war.in_progress?
      ensure_war_polling_active
      @war_data = Rails.cache.read(@faction.war_cache_key)
      @polling_active = @faction.war_polling_active?
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

  def sync
    unless can_sync?
      redirect_to faction_ranked_wars_path(@faction), alert: "Please wait #{seconds_until_sync} seconds before syncing again."
      return
    end

    api_key = @faction.faction_setting&.torn_api_key
    if api_key.blank?
      redirect_to faction_settings_path(@faction), alert: "Torn API key must be configured before syncing wars."
      return
    end

    # Fetch the last 10 ranked wars synchronously
    wars = TornApi::Faction::RankedWars.new(api_key, @faction.torn_id).fetch(limit: 10)
    wars_needing_reports = []

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

      # Track wars that need detailed reports
      if ranked_war.completed? && ranked_war.our_members.empty?
        wars_needing_reports << war_data["id"]
      end

      ranked_war.save!
    end

    # Fetch detailed reports synchronously with 1 second delay between requests
    wars_needing_reports.each do |torn_war_id|
      sleep 1
      fetch_war_report(api_key, torn_war_id)
    end

    # Record sync time for cooldown
    session[:last_ranked_wars_sync_at] = Time.current.to_i

    redirect_to faction_ranked_wars_path(@faction), notice: "Synced #{wars.size} ranked wars."
  end

  private

  def ensure_war_polling_active
    return if @faction.war_polling_active?
    return unless @faction.faction_setting&.torn_api_key?

    @faction.start_war_polling!
  end

  def check_tracking_enabled
    return if performed?

    unless @faction.track_stats
      @tracking_disabled = true
    end
  end

  def can_sync?
    return true unless session[:last_ranked_wars_sync_at]
    Time.current - Time.at(session[:last_ranked_wars_sync_at]) >= SYNC_COOLDOWN
  end

  def seconds_until_sync
    return 0 unless session[:last_ranked_wars_sync_at]
    remaining = SYNC_COOLDOWN - (Time.current - Time.at(session[:last_ranked_wars_sync_at]))
    [ remaining.to_i, 0 ].max
  end

  def fetch_war_report(api_key, torn_war_id)
    ranked_war = @faction.ranked_wars.find_by(torn_war_id: torn_war_id)
    return unless ranked_war

    report = TornApi::Faction::RankedWarReport.new(api_key, torn_war_id).fetch
    return unless report

    our_faction_data = report["factions"].find { |f| f["id"] == @faction.torn_id }
    their_faction_data = report["factions"].find { |f| f["id"] != @faction.torn_id }
    return unless our_faction_data && their_faction_data

    ranked_war.update!(
      forfeit: report["forfeit"] || false,
      our_attacks: our_faction_data["attacks"] || 0,
      their_attacks: their_faction_data["attacks"] || 0,
      rank_before: our_faction_data.dig("rank", "before"),
      rank_after: our_faction_data.dig("rank", "after"),
      respect_gained: our_faction_data.dig("rewards", "respect") || 0,
      points_gained: our_faction_data.dig("rewards", "points") || 0,
      our_members: our_faction_data["members"] || [],
      their_members: their_faction_data["members"] || [],
      our_rewards: our_faction_data["rewards"] || {},
      their_rewards: their_faction_data["rewards"] || {}
    )
  end

  def calculate_member_performance(wars)
    return {} if wars.empty?

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

    # Calculate averages and sort by total score
    performance.values.map do |p|
      p[:avg_attacks] = p[:wars_participated] > 0 ? (p[:total_attacks].to_f / p[:wars_participated]).round(1) : 0
      p[:avg_score] = p[:wars_participated] > 0 ? (p[:total_score] / p[:wars_participated]).round(1) : 0
      p[:avg_respect_per_hit] = p[:total_attacks] > 0 ? (p[:total_score] / p[:total_attacks]).round(2) : 0
      p
    end.sort_by { |p| -p[:total_score] }
  end
end
