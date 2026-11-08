class CompanyNewsEntry < ApplicationRecord
  def self.record!(company_torn_id, entries)
    rows = entries.filter_map do |entry|
      next if entry["id"].blank? || entry["timestamp"].blank?

      {
        company_torn_id: company_torn_id,
        news_id: entry["id"].to_s,
        occurred_at: Time.zone.at(entry["timestamp"]),
        text: entry["text"].to_s
      }
    end
    return if rows.empty?

    upsert_all(rows, unique_by: [ :company_torn_id, :news_id ])
  end
end
