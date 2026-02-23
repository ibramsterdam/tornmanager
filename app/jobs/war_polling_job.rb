class WarPollingJob < ApplicationJob
  POLL_INTERVAL = 6.seconds
  CACHE_TTL = 30.seconds

  queue_as :faction_polling

  def perform(faction_id)
    faction = Faction.find_by(id: faction_id)
    return unless faction&.war_polling_active?

    war = faction.current_war
    unless war
      faction.update!(war_polling_active: false)
      return
    end

    setting = faction.faction_setting
    unless setting&.torn_api_key?
      Rails.logger.warn("WarPollingJob: No API key for faction #{faction_id}, stopping polling")
      faction.update!(war_polling_active: false)
      return
    end

    war_data = build_war_data(faction, war, setting)
    Rails.cache.write(faction.war_cache_key, war_data, expires_in: CACHE_TTL)

    WarPollingJob.set(wait: POLL_INTERVAL).perform_later(faction_id)
  rescue StandardError => e
    Rails.logger.error("WarPollingJob: Error for faction #{faction_id}: #{e.class} - #{e.message}")
    WarPollingJob.set(wait: POLL_INTERVAL).perform_later(faction_id) if faction&.war_polling_active?
  end

  private

  def build_war_data(faction, war, setting)
    enemy_members = fetch_enemy_members(setting.torn_api_key, war.opponent_faction_id)
    spy_reports = faction.spy_reports.where(torn_id: enemy_members.keys).index_by(&:torn_id)

    members = enemy_members.transform_values do |member|
      spy = spy_reports[member.id]
      build_member_data(member, spy)
    end

    {
      enemy_faction_id: war.opponent_faction_id,
      enemy_faction_name: war.opponent_faction_name,
      our_score: war.our_score,
      their_score: war.their_score,
      target_score: war.target_score,
      started_at: war.started_at.iso8601,
      members: members,
      cached_at: Time.current.iso8601
    }
  end

  def fetch_enemy_members(api_key, enemy_faction_id)
    members = TornApi::Faction::Members.new(api_key, enemy_faction_id).fetch
    members.index_by(&:id)
  end

  def build_member_data(member, spy)
    data = {
      torn_id: member.id,
      name: member.name,
      level: member.level,
      status: build_status(member),
      last_action: build_last_action(member)
    }

    if spy
      data[:stats] = spy.stats_hash
      data[:stats_timestamp] = spy.spied_at&.iso8601
    end

    data
  end

  def build_last_action(member)
    {
      status: member.last_action_status,
      timestamp: member.last_action_timestamp,
      relative: member.last_action_relative
    }
  end

  def build_status(member)
    state = member.status_state
    if state && state != "Okay"
      status = { state: state }
      status[:description] = member.status_description if member.status_description.present?
      status[:until] = Time.at(member.status_until.to_i).iso8601 if member.status_until.to_i > 0
      status
    else
      { state: "Okay" }
    end
  end
end
