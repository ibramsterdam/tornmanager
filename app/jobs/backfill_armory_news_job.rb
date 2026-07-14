class BackfillArmoryNewsJob < FactionApiJob
  BACKFILL_FLOOR = Time.utc(2026, 1, 1).to_i
  PAGE_DELAY = 1.minute

  queue_with_priority 100
  limits_concurrency to: 1, key: FACTION_KEY_LOOKUP, group: CONCURRENCY_GROUP

  def perform(faction_id, cursor = nil)
    faction = Faction.find_by(id: faction_id)
    return unless faction

    api_key = faction.torn_api_key&.key
    return unless api_key

    if cursor.nil?
      oldest = faction.armory_news_entries.minimum(:occurred_at)
      cursor = oldest ? oldest.to_i - 1 : Time.current.to_i
    end

    if cursor <= BACKFILL_FLOOR
      faction.update!(armory_backfill_pending: false)
      return
    end

    client = TornApi::Faction::ArmoryNews.new(api_key)
    batch = client.fetch(to: cursor, limit: 100)

    if batch.empty?
      faction.update!(armory_backfill_pending: false)
      return
    end

    records = batch.map { |entry| build_record(faction.id, entry) }
    ArmoryNewsEntry.insert_all(records, unique_by: [ :faction_id, :torn_news_id ])

    oldest_in_batch = batch.map { |e| e[:timestamp] }.min
    next_cursor = oldest_in_batch - 1

    if batch.size == 100 && next_cursor > BACKFILL_FLOOR
      BackfillArmoryNewsJob.set(wait: PAGE_DELAY).perform_later(faction_id, next_cursor)
    else
      faction.update!(armory_backfill_pending: false)
    end
  rescue TornApi::ApiError => e
    Rails.logger.error("BackfillArmoryNewsJob: Failed for faction #{faction_id}: #{e.message}")
    if e.message.include?("Daily read limit") || e.message.include?("rate limit")
      BackfillArmoryNewsJob.set(wait: 1.hour).perform_later(faction_id, cursor)
    end
  end

  private

  def build_record(faction_id, entry)
    {
      faction_id: faction_id,
      torn_news_id: entry[:id].to_s,
      player_id: entry[:player_id],
      player_name: entry[:player_name],
      action: entry[:action].to_s,
      item: entry[:item],
      text: entry[:text],
      occurred_at: Time.at(entry[:timestamp]),
      created_at: Time.current
    }
  end
end
