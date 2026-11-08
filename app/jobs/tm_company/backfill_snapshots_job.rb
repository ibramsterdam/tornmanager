module TmCompany
  class BackfillSnapshotsJob < TornApiJob
    queue_with_priority 100
    limits_concurrency to: 1, key: "company_backfill_snapshots", group: CONCURRENCY_GROUP

    MAX_DAYS = 60

    def self.needed?
      CompanySnapshot.where(date: (Date.current - MAX_DAYS)...Date.current).distinct.count(:date) < MAX_DAYS
    end

    def perform(days = MAX_DAYS)
      api_key = Recruiter::KeyPool.next_key
      return Rails.logger.warn("TmCompany::BackfillSnapshotsJob: no api key, skipping") unless api_key

      existing = CompanySnapshot.distinct.pluck(:date).to_set

      (1..days).each do |days_ago|
        date = Date.current - days_ago
        next if existing.include?(date)

        rows = TornApi::Company::Snapshot.new(api_key, timestamp: date.to_time(:utc) + 12.hours, comment: "tmcompany").fetch
        CompanySnapshot.record!(rows, date)
        sleep(RATE_LIMIT_SLEEP)
      rescue TornApi::NotFoundError
        break
      end
    end
  end
end
