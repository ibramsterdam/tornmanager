class Factions::RankedWarsController < ApplicationController
  include FactionAccess

  skip_before_action :require_authentication, if: :public_wars_enabled?
  before_action :require_faction_whitelisted, unless: :public_wars_enabled?
  before_action :check_tracking_enabled

  def index
    return if @tracking_disabled

    refresh_latest_wars

    @wars = @faction.ranked_wars.recent.includes(:faction)

    completed_wars = @wars.completed
    @wins = completed_wars.won.count
    @losses = completed_wars.lost.count

    @ongoing_war = @wars.ongoing.select(&:in_progress?).first

    @member_performance = calculate_member_performance(completed_wars)
  end

  def show
    @war = @faction.ranked_wars.find_by(torn_war_id: params[:id])

    unless @war
      redirect_to faction_ranked_wars_path(@faction), alert: "War not found."
      return
    end

    if @war.ongoing?  # Both scheduled and in_progress
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

  private

  def ensure_war_polling_active
    return unless @faction.faction_setting&.torn_api_key?

    if @faction.war_polling_active?
      restart_war_polling! unless Rails.cache.exist?(@faction.war_cache_key)
    else
      @faction.start_war_polling!
    end
  end

  def restart_war_polling!
    Rails.logger.info("Restarting dead war polling for faction #{@faction.torn_id}")
    @faction.start_war_polling!
  end

  def check_tracking_enabled
    return if performed?

    unless @faction.track_stats
      @tracking_disabled = true
    end
  end

  def public_wars_enabled?
    find_faction unless @faction
    @faction&.public_wars?
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
    Rails.logger.warn("[RankedWarsController] Failed to refresh latest wars: #{e.message}")
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

    performance.values.map do |p|
      p[:avg_attacks] = p[:wars_participated] > 0 ? (p[:total_attacks].to_f / p[:wars_participated]).round(1) : 0
      p[:avg_score] = p[:wars_participated] > 0 ? (p[:total_score] / p[:wars_participated]).round(1) : 0
      p[:avg_respect_per_hit] = p[:total_attacks] > 0 ? (p[:total_score] / p[:total_attacks]).round(2) : 0
      p
    end.sort_by { |p| -p[:total_score] }
  end
end
