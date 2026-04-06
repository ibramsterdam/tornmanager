class Factions::Leadership::ArmoryController < Factions::Leadership::BaseController
  def show
    api_key = @faction.torn_api_key&.key
    raise TornApi::InvalidKeyError, "No API key configured" unless api_key

    loans_by_member = Hash[TornApi::Faction::Armory.new(api_key).fetch_by_member]

    @armory_news = @faction.armory_news_entries
      .recent(2.months)
      .newest_first
      .map { |e| entry_to_hash(e) }

    @backfill_in_progress = @faction.armory_backfill_pending?

    member_names = @faction.users.where(torn_id: loans_by_member.keys).pluck(:torn_id, :name).to_h

    @members = loans_by_member.map do |member_id, slots|
      total = slots.values.sum(&:size)
      name = member_names[member_id] || "Unknown"
      { torn_id: member_id, name: name, slots: slots, total: total }
    end.sort_by { |m| -m[:total] }

    @news_by_member = @armory_news
      .select { |e| e[:action].in?([ :loaned, :returned ]) }
      .group_by { |e| e[:player_id] }
  rescue TornApi::InvalidKeyError => e
    redirect_to faction_leadership_path(@faction), alert: "API key error: #{e.message}"
  rescue TornApi::ApiError => e
    redirect_to faction_leadership_path(@faction), alert: "API error: #{e.message}"
  end

  def sync
    api_key = @faction.torn_api_key&.key
    client = TornApi::Faction::ArmoryNews.new(api_key)

    entries = client.fetch_all(since: Time.current.beginning_of_day, max_entries: 1000)
    if entries.any?
      records = entries.map { |e| build_record(e) }
      ArmoryNewsEntry.insert_all(records, unique_by: [ :faction_id, :torn_news_id ])
    end

    redirect_to faction_leadership_armory_path(@faction), notice: "Synced #{entries.size} activity entries."
  rescue TornApi::ApiError => e
    redirect_to faction_leadership_armory_path(@faction), alert: "Sync failed: #{e.message}"
  end

  private

  def build_record(entry)
    {
      faction_id: @faction.id,
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

  def entry_to_hash(entry)
    {
      id: entry.torn_news_id,
      text: entry.text,
      timestamp: entry.occurred_at.to_i,
      player_name: entry.player_name,
      player_id: entry.player_id,
      action: entry.action.to_sym,
      item: entry.item
    }
  end
end
