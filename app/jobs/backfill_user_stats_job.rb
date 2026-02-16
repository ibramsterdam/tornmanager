class BackfillUserStatsJob < ApplicationJob
  queue_as :default

  STAT_MAPPING_BATCH_1 = {
    "xantaken" => :drugs_xanax,
    "cantaken" => :drugs_cannabis,
    "refills" => :other_refills_energy,
    "nerverefills" => :other_refills_nerve,
    "boostersused" => :items_used_boosters,
    "statenhancersused" => :items_used_stat_enhancers,
    "contractscompleted" => :missions_contracts_total,
    "criminaloffenses" => :crimes_offenses_total,
    "timeplayed" => :other_activity_time,
    "networth" => :networth_total
  }.freeze

  STAT_MAPPING_BATCH_2 = {
    "moneymugged" => :attacking_networth_money_mugged
  }.freeze

  def perform(user_id, start_date, end_date)
    user = User.find(user_id)
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling backfill for user #{user.name} (#{user.torn_id}): #{dates.size} days")

    delay = 0.seconds
    jobs_scheduled = 0

    existing_snapshots = user.personal_stat_snapshots
                            .where(date: dates)
                            .index_by(&:date)

    dates.each do |date|
      snapshot = existing_snapshots[date]

      missing_stats_batch_1 = STAT_MAPPING_BATCH_1.select do |api_stat, db_column|
        snapshot.nil? || snapshot.send(db_column).nil?
      end

      missing_stats_batch_2 = STAT_MAPPING_BATCH_2.select do |api_stat, db_column|
        snapshot.nil? || snapshot.send(db_column).nil?
      end

      if missing_stats_batch_1.any?
        BackfillSingleStatJob.set(wait: delay).perform_later(
          user.id,
          date.to_s,
          missing_stats_batch_1.to_json
        )
        delay += 1.second
        jobs_scheduled += 1
      end

      if missing_stats_batch_2.any?
        BackfillSingleStatJob.set(wait: delay).perform_later(
          user.id,
          date.to_s,
          missing_stats_batch_2.to_json
        )
        delay += 1.second
        jobs_scheduled += 1
      end
    end

    Rails.logger.info("Scheduled #{jobs_scheduled} stat fetch jobs for user #{user.name}")
  end
end
