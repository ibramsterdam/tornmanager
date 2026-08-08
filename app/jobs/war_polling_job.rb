class WarPollingJob < ApplicationJob
  POLL_INTERVAL = 6.seconds
  CACHE_TTL = 30.seconds

  queue_as :war
  limits_concurrency to: 1, key: ->(faction_id) { "war_polling_faction_#{faction_id}" }

  def perform(faction_id)
    faction = Faction.find_by(id: faction_id)
    return unless faction&.war_polling_active?

    war = faction.current_war
    unless war
      faction.update!(war_polling_active: false)
      return
    end

    unless faction.torn_api_key.present?
      Rails.logger.warn("WarPollingJob: No API key for faction #{faction_id}, stopping polling")
      faction.update!(war_polling_active: false)
      return
    end

    @previous_data = Rails.cache.read(faction.war_cache_key) || {}

    war_data = build_war_data(faction, war)
    Rails.cache.write(faction.war_cache_key, war_data, expires_in: CACHE_TTL)

    WarPollingJob.set(wait: POLL_INTERVAL).perform_later(faction_id)
  rescue StandardError => e
    Rails.logger.error("WarPollingJob: Error for faction #{faction_id}: #{e.class} - #{e.message}")
    WarPollingJob.set(wait: POLL_INTERVAL).perform_later(faction_id) if faction&.war_polling_active?
  end

  private

  def build_war_data(faction, war)
    enemy_members = fetch_enemy_members(faction.torn_api_key.key, war.opponent_faction_id)
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

      if state == "Traveling"
        status[:plane_type] = member.plane_image_type
        travel = parse_travel(member.status_description)
        if travel
          status[:destination] = travel[:destination]
          status[:returning] = travel[:returning]
        end
        status[:travel_started_at] = resolve_travel_started_at(member)
      end

      status
    else
      { state: "Okay" }
    end
  end

  # Torn describes travel as "Traveling from Torn to Canada" (outbound) or
  # "Traveling from Canada to Torn" (returning). Destination is always the
  # non-Torn side, since flight times are symmetric. Legacy formats kept as
  # fallback for cached blobs written before the API change.
  def parse_travel(description)
    return nil unless description.present?

    if (match = description.match(/Traveling from (.+) to (.+)/i))
      returning = match[2].strip.casecmp?("Torn")
      { destination: returning ? match[1].strip : match[2].strip, returning: returning }
    elsif (match = description.match(/Returning to Torn from (.+)/i))
      { destination: match[1].strip, returning: true }
    elsif (match = description.match(/Traveling to (.+)/i))
      { destination: match[1].strip, returning: false }
    end
  end

  def resolve_travel_started_at(member)
    previous_members = @previous_data[:members] || @previous_data["members"] || {}
    member_key = member.id.to_s
    previous_member = previous_members[member_key] || previous_members[member.id]

    unless previous_member
      return Time.current.iso8601
    end

    previous_status = previous_member[:status] || previous_member["status"] || {}
    previous_state = previous_status[:state] || previous_status["state"]
    previous_started = previous_status[:travel_started_at] || previous_status["travel_started_at"]

    if previous_state == "Traveling" && previous_started.present?
      previous_started
    else
      Time.current.iso8601
    end
  end
end
