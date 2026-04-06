class FetchArmoryNewsJob < FactionApiJob
  limits_concurrency to: 1, key: ->(faction_id) { faction_id }, group: "FactionApiCalls"

  def perform(faction_id)
    faction = Faction.find_by(id: faction_id)
    return unless faction

    api_key = faction.torn_api_key&.key
    return unless api_key

    client = TornApi::Faction::ArmoryNews.new(api_key)
    latest = faction.armory_news_entries.maximum(:occurred_at)
    cursor = latest ? latest.to_i + 1 : 1.day.ago.to_i

    loop do
      batch = client.fetch(from: cursor, limit: 100, sort: "ASC")
      break if batch.empty?

      records = batch.map { |entry| build_record(faction.id, entry) }
      ArmoryNewsEntry.insert_all(records, unique_by: [ :faction_id, :torn_news_id ])

      break if batch.size < 100
      cursor = batch.map { |e| e[:timestamp] }.max + 1
    end
  rescue TornApi::ApiError => e
    Rails.logger.error("FetchArmoryNewsJob: Failed for faction #{faction_id}: #{e.message}")
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
