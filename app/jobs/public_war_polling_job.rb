class PublicWarPollingJob < ApplicationJob
  POLL_INTERVAL = 3.seconds
  CACHE_TTL = 30.seconds

  DESTINATION_PATTERN = /(?:Traveling to |Returning to Torn from |In )(.+)/i

  queue_as :war
  limits_concurrency to: 1, key: ->(lobby_id) { "public_war_polling_#{lobby_id}" }

  def perform(lobby_id)
    lobby = PublicWarLobby.find_by(id: lobby_id)
    return unless lobby

    api_key = Rails.cache.read(lobby.api_key_cache_key)
    unless api_key
      lobby.terminate!
      return
    end

    @previous_data = Rails.cache.read(lobby.war_cache_key) || {}

    war_data = build_war_data(api_key, lobby)
    Rails.cache.write(lobby.war_cache_key, war_data, expires_in: CACHE_TTL)

    PublicWarPollingJob.set(wait: POLL_INTERVAL).perform_later(lobby_id)
  rescue TornApi::InvalidKeyError
    Rails.logger.warn("PublicWarPollingJob: Invalid API key for lobby #{lobby_id}, terminating")
    lobby&.terminate!
  rescue StandardError => e
    Rails.logger.error("PublicWarPollingJob: Error for lobby #{lobby_id}: #{e.class} - #{e.message}")
    PublicWarPollingJob.set(wait: POLL_INTERVAL).perform_later(lobby_id) if lobby&.persisted?
  end

  private

  def build_war_data(api_key, lobby)
    enemy_members = fetch_enemy_members(api_key, lobby.faction_torn_id)

    members = enemy_members.transform_values do |member|
      build_member_data(member)
    end

    {
      faction_name: lobby.faction_name,
      opponent_faction_name: lobby.opponent_faction_name,
      members: members,
      cached_at: Time.current.iso8601
    }
  end

  def fetch_enemy_members(api_key, faction_torn_id)
    members = TornApi::Faction::Members.new(api_key, faction_torn_id).fetch
    members.index_by(&:id)
  end

  def build_member_data(member)
    {
      torn_id: member.id,
      name: member.name,
      level: member.level,
      status: build_status(member),
      last_action: build_last_action(member)
    }
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
        status[:destination] = extract_destination(member.status_description)
        status[:travel_started_at] = resolve_travel_started_at(member)
      end

      status
    else
      { state: "Okay" }
    end
  end

  def extract_destination(description)
    return nil unless description.present?

    match = description.match(DESTINATION_PATTERN)
    match&.[](1)
  end

  def resolve_travel_started_at(member)
    previous_members = @previous_data[:members] || @previous_data["members"] || {}
    member_key = member.id.to_s
    previous_member = previous_members[member_key] || previous_members[member.id]

    return nil unless previous_member

    previous_status = previous_member[:status] || previous_member["status"] || {}
    previous_state = previous_status[:state] || previous_status["state"]
    previous_started = previous_status[:travel_started_at] || previous_status["travel_started_at"]

    if previous_state == "Traveling" && previous_started.present?
      previous_started
    elsif previous_state != "Traveling"
      Time.current.iso8601
    end
  end
end
