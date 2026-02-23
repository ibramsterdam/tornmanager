class FactionsController < ApplicationController
  include FactionAccess

  before_action :require_faction_whitelisted, only: [ :show ]

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

    summary = ComplianceSummary.new(@faction)

    @total_members = summary.member_rows.size
    @compliant_count = summary.compliant_count
    @warning_count = summary.warning_count
    @non_compliant_count = summary.non_compliant_count
    @worst_performers = summary.worst_performers(5)

    @xanax_target = @faction.xanax_target
    @energy_target = @faction.energy_refill_target
    @nerve_target = @faction.nerve_refill_target

    @current_war = @faction.current_war
    refresh_current_war_scores if @current_war
    ensure_war_polling_active if @current_war
  end

  private

  def ensure_war_polling_active
    return unless @faction.faction_setting&.torn_api_key?

    if @faction.war_polling_active?
      # Flag is set but cache is empty/stale — the job chain likely died. Restart it.
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
end
