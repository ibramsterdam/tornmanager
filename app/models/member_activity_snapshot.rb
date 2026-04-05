class MemberActivitySnapshot < ApplicationRecord
  belongs_to :faction

  validates :torn_member_id, :member_name, :recorded_at, :status, :hour_utc, :day_of_week, presence: true

  scope :recent, ->(days = 7) { where(recorded_at: days.days.ago..) }
  scope :active, -> { where(status: %w[Online Idle]) }

  def self.calendar_heatmap(faction_id, start_date, end_date)
    where(faction_id: faction_id)
      .where(recorded_at: start_date.beginning_of_day..end_date.end_of_day)
      .active
      .group(Arel.sql("date(recorded_at)"), :hour_utc)
      .count
  end

  def self.member_summary(faction_id, days: 7)
    where(faction_id: faction_id)
      .recent(days)
      .group(:torn_member_id, :member_name)
      .select(
        "torn_member_id",
        "member_name",
        "COUNT(*) as total_snapshots",
        "SUM(CASE WHEN status = 'Online' THEN 1 ELSE 0 END) as online_count",
        "SUM(CASE WHEN status IN ('Online', 'Idle') THEN 1 ELSE 0 END) as active_count"
      )
      .order(Arel.sql("SUM(CASE WHEN status = 'Online' THEN 1 ELSE 0 END) DESC"))
  end

  def self.peak_hour(faction_id, days: 7)
    where(faction_id: faction_id)
      .recent(days)
      .active
      .group(:hour_utc)
      .order("count_all DESC")
      .limit(1)
      .count
      .keys
      .first
  end
end
