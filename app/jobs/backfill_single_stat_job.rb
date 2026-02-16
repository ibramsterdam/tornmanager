class BackfillSingleStatJob < ApplicationJob
  queue_as :default

  def perform(user_id, date_str, stat_mapping_json)
    user = User.find(user_id)
    date = Date.parse(date_str)
    stat_mapping = JSON.parse(stat_mapping_json)
    api_key = OwnerCredentials.api_key

    return Rails.logger.error("No API key found") if api_key.blank?

    timestamp = date.to_time.to_i
    fetched_data = {}

    stat_mapping.each do |api_stat_name, db_column|
      value = fetch_stat(user.torn_id, api_stat_name, timestamp, api_key)
      fetched_data[db_column] = value if value
    end

    return if fetched_data.empty?

    snapshot = user.personal_stat_snapshots.find_or_initialize_by(date: date)
    snapshot.assign_attributes(fetched_data)
    snapshot.created_at = date.to_time.midday if snapshot.new_record?

    if snapshot.save
      Rails.logger.debug("Upserted snapshot for user #{user.torn_id} on #{date}: #{fetched_data.keys.join(', ')}")
    else
      Rails.logger.error("Failed to save snapshot for user #{user.torn_id} on #{date}: #{snapshot.errors.full_messages.join(', ')}")
    end
  end

  private

  def fetch_stat(torn_id, api_stat_name, timestamp, api_key)
    api = TornApi::User::HistoricalPersonalStat.new(api_key, torn_id)
    api.fetch(api_stat_name, timestamp)
  rescue TornApi::ApiError => e
    Rails.logger.error("API error for stat #{api_stat_name}: #{e.message}")
    nil
  end
end
