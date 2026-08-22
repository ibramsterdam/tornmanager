module Recruiter
  class SyncRosterJob < TornApiJob
    queue_with_priority 50
    limits_concurrency to: 1, key: "recruiter", group: CONCURRENCY_GROUP

    BATCH_SIZE = 2_000

    def perform
      api_key = KeyPool.next_key
      return Rails.logger.warn("Recruiter::SyncRosterJob: no recruiter api key, skipping") unless api_key

      synced_at = Time.current
      sync_companies(api_key, synced_at)
      sync_employment(api_key, synced_at)
      disconnect_departed(synced_at)
    end

    private

    def sync_companies(api_key, synced_at)
      companies = TornApi::Company::Snapshot.new(api_key).fetch
      companies.each_slice(BATCH_SIZE) do |slice|
        rows = slice.map do |company|
          {
            torn_id: company.torn_id,
            name: company.name,
            company_type_id: company.company_type_id,
            rating: company.rating,
            employees_hired: company.employees_hired,
            synced_at: synced_at
          }
        end
        Company.upsert_all(rows, unique_by: :torn_id, record_timestamps: true)
      end
      Company.where("synced_at IS NULL OR synced_at < ?", synced_at).delete_all
    end

    def sync_employment(api_key, synced_at)
      players = TornApi::User::Snapshot.new(api_key).fetch
      players.each_slice(BATCH_SIZE) do |slice|
        rows = slice.map do |player|
          {
            torn_id: player.torn_id,
            name: player.name,
            level: player.level,
            company_id: player.company_id,
            company_director: player.director,
            company_synced_at: synced_at
          }
        end
        User.upsert_all(
          rows,
          unique_by: :torn_id,
          update_only: [ :name, :level, :company_id, :company_director, :company_synced_at ],
          record_timestamps: true
        )
      end
    end

    def disconnect_departed(synced_at)
      User.employed
        .where("company_synced_at IS NULL OR company_synced_at < ?", synced_at)
        .update_all(company_id: nil, company_director: false)
    end
  end
end
