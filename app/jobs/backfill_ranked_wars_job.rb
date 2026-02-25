class BackfillRankedWarsJob < ApplicationJob
  queue_as :default

  def perform(faction_id, limit: 20)
    faction = Faction.find_by(id: faction_id)
    return unless faction

    api_key = faction.faction_setting&.torn_api_key || OwnerCredentials.api_key
    return unless api_key.present?

    wars = TornApi::Faction::RankedWars.new(api_key, faction.torn_id).fetch(limit: limit)
    wars_needing_reports = []

    wars.each do |war_data|
      our_faction_data = war_data["factions"].find { |f| f["id"] == faction.torn_id }
      their_faction_data = war_data["factions"].find { |f| f["id"] != faction.torn_id }

      next unless our_faction_data && their_faction_data

      ranked_war = faction.ranked_wars.find_or_initialize_by(torn_war_id: war_data["id"])

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

      if ranked_war.completed? && ranked_war.our_members.empty?
        wars_needing_reports << war_data["id"]
      end

      ranked_war.save!
    end

    wars_needing_reports.each do |torn_war_id|
      sleep 1
      fetch_war_report(faction, api_key, torn_war_id)
    end

    Rails.logger.info("[BackfillRankedWarsJob] Backfilled #{wars.size} wars for faction #{faction.name} (#{wars_needing_reports.size} reports fetched)")
  end

  private

  def fetch_war_report(faction, api_key, torn_war_id)
    ranked_war = faction.ranked_wars.find_by(torn_war_id: torn_war_id)
    return unless ranked_war

    report = TornApi::Faction::RankedWarReport.new(api_key, torn_war_id).fetch
    return unless report

    our_faction_data = report["factions"].find { |f| f["id"] == faction.torn_id }
    their_faction_data = report["factions"].find { |f| f["id"] != faction.torn_id }
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
end
