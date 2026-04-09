class Recon::CollectTrainingSampleJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "recon_collect", group: "ReconApiCalls"

  BATCH_SIZE = 10

  def perform(player_id:, spied_at:)
    spied_at_date = Date.parse(spied_at.to_s)

    sample = Recon::TrainingSample.find_by(player_id: player_id, spied_at: spied_at_date)
    return unless sample

    api_key = AdminCredentials.api_key
    return if api_key.blank?

    timestamp = spied_at_date.end_of_day.to_i

    personalstats = fetch_personalstats(api_key, player_id, timestamp)
    profile = Recon::TornApi::Profile.new(api_key, player_id).fetch

    features = Recon::FeatureSet.build(personalstats: personalstats, profile: profile)

    sample.update!(features.slice(*Recon::TrainingSample::FEATURE_COLUMNS))
  rescue TornApi::ApiError => e
    Rails.logger.error("Recon::CollectTrainingSampleJob failed for player #{player_id}: #{e.message}")
  end

  private

  def fetch_personalstats(api_key, player_id, timestamp)
    batches = Recon::FeatureSet::API_STAT_NAMES.each_slice(BATCH_SIZE).to_a

    batches.reduce({}) do |result, batch|
      stats = Recon::TornApi::PersonalStats.new(
        api_key, player_id, stats: batch, timestamp: timestamp
      ).fetch
      result.merge(stats)
    end
  end
end
