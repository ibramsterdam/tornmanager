class FetchMemberActivityJob < FactionApiJob
  limits_concurrency to: 1, key: ->(faction_id) { faction_id }, group: "FactionApiCalls"

  def perform(faction_id)
    faction = Faction.find_by(id: faction_id)
    return unless faction

    api_key = faction.torn_api_key&.key
    return unless api_key

    members = TornApi::Faction::Members.new(api_key, faction.torn_id).fetch
    now = Time.current

    snapshots = members.map do |member|
      {
        faction_id: faction.id,
        torn_member_id: member.id,
        member_name: member.name,
        recorded_at: now,
        hour_utc: now.hour,
        day_of_week: now.wday,
        status: member.last_action_status || "Offline",
        created_at: now,
        updated_at: now
      }
    end

    MemberActivitySnapshot.insert_all(snapshots) if snapshots.any?
  rescue TornApi::ApiError => e
    Rails.logger.error("FetchMemberActivityJob: Failed for faction #{faction_id}: #{e.message}")
  end
end
