class FetchWarAttacksJob < ApplicationJob
  queue_as :default

  MAX_PAGES = 100

  def perform(ranked_war_id)
    war = RankedWar.find_by(id: ranked_war_id)
    return unless war

    faction = war.faction
    api_key = faction.torn_api_key
    return unless api_key&.faction_access?

    existing_ids = war.ranked_war_attacks.pluck(:torn_attack_id).to_set
    stored = 0

    # Resume from where we left off — use the earliest stored attack's timestamp
    # so we paginate backwards from war end into uncollected territory
    earliest_stored = war.ranked_war_attacks.minimum(:started)
    current_to = earliest_stored ? earliest_stored : war.ended_at&.to_i
    pages = 0

    loop do
      break if pages >= MAX_PAGES

      result = TornApi::Faction::Attacks.new(
        api_key.key,
        from: war.started_at.to_i,
        to: current_to,
        filters: "outgoing"
      ).fetch

      result.attacks.each do |attack|
        next unless attack.is_ranked_war
        next if existing_ids.include?(attack.id)

        store_attack(war, attack)
        existing_ids.add(attack.id)
        stored += 1
      end

      pages += 1

      break unless result.prev_url

      new_to = extract_to_param(result.prev_url)
      break unless new_to
      current_to = new_to
    end

    integrity_check(war, faction)

    Rails.logger.info("[FetchWarAttacksJob] War #{war.torn_war_id}: stored #{stored} attacks in #{pages} pages")
  end

  private

  def store_attack(war, attack)
    war.ranked_war_attacks.create!(
      torn_attack_id: attack.id,
      code: attack.code,
      attacker_id: attack.attacker_id,
      attacker_name: attack.attacker_name,
      attacker_level: attack.attacker_level,
      attacker_faction_id: attack.attacker_faction_id,
      attacker_faction_name: attack.attacker_faction_name,
      defender_id: attack.defender_id,
      defender_name: attack.defender_name,
      defender_level: attack.defender_level,
      defender_faction_id: attack.defender_faction_id,
      defender_faction_name: attack.defender_faction_name,
      started: attack.started,
      ended: attack.ended,
      result: attack.result,
      respect_gain: attack.respect_gain,
      respect_loss: attack.respect_loss,
      chain: attack.chain,
      is_stealthed: attack.is_stealthed,
      is_interrupted: attack.is_interrupted,
      is_raid: attack.is_raid,
      fair_fight: attack.fair_fight,
      war: attack.war,
      retaliation: attack.retaliation,
      group_modifier: attack.group,
      overseas: attack.overseas,
      chain_modifier: attack.chain_modifier,
      warlord: attack.warlord,
      finishing_hit_effects: attack.finishing_hit_effects
    )
  end

  def extract_to_param(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || "").to_h
    params["to"]&.to_i
  end

  def integrity_check(war, faction)
    our_count = war.ranked_war_attacks.outgoing(faction.torn_id).count
    expected_ours = war.our_attacks || 0

    if our_count < expected_ours
      Rails.logger.warn(
        "[FetchWarAttacksJob] Integrity check: war #{war.torn_war_id} outgoing #{our_count}/#{expected_ours}"
      )
    else
      Rails.logger.info(
        "[FetchWarAttacksJob] Integrity check passed for war #{war.torn_war_id}: #{our_count} outgoing attacks"
      )
    end
  end
end
