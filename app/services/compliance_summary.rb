class ComplianceSummary
  include FactionHelper

  CACHE_TTL = 1.hour

  attr_reader :faction, :start_date, :end_date, :member_rows,
              :compliant_count, :warning_count, :non_compliant_count, :total_days

  def initialize(faction, start_date: nil, end_date: nil)
    @faction = faction
    @start_date = start_date || PersonalStatSnapshot.tracking_start_date
    @end_date = end_date || PersonalStatSnapshot.tracking_end_date
    @total_days = (@end_date - @start_date).to_i + 1
    @member_rows = []

    load_cached_results
  end

  def worst_performers(limit = 5)
    member_rows.sort_by { |row| row[:compliance_score] }.first(limit)
  end

  private

  def load_cached_results
    cached = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { compute }

    @member_rows = cached[:member_rows]
    @compliant_count = cached[:compliant_count]
    @warning_count = cached[:warning_count]
    @non_compliant_count = cached[:non_compliant_count]
  end

  def cache_key
    "compliance_summary:#{faction.id}:#{start_date}:#{end_date}:#{faction.updated_at.to_i}"
  end

  def compute
    query_start_date = start_date - 1.day
    active_users = faction.users.active.to_a

    snapshots_by_user = PersonalStatSnapshot
      .where(user_id: active_users.map(&:id))
      .where(date: query_start_date..end_date)
      .order(:date)
      .group_by(&:user_id)

    rows = active_users.filter_map do |user|
      user_snapshots = snapshots_by_user[user.id] || []
      build_member_row(user, user_snapshots)
    end

    {
      member_rows: rows,
      compliant_count: rows.count { |row| row[:compliance_level] == :compliant },
      warning_count: rows.count { |row| row[:compliance_level] == :warning },
      non_compliant_count: rows.count { |row| row[:compliance_level] == :danger }
    }
  end

  def build_member_row(user, snapshots)
    xanax_stats = calculate_stat(snapshots, :drugs_xanax)
    energy_stats = calculate_stat(snapshots, :other_refills_energy)
    nerve_stats = calculate_stat(snapshots, :other_refills_nerve)
    missions_stats = calculate_stat(snapshots, :missions_contracts_total)
    crimes_stats = calculate_stat(snapshots, :crimes_offenses_total)
    activity_stats = calculate_stat(snapshots, :other_activity_time)
    networth_stats = calculate_stat(snapshots, :networth_total)

    return if xanax_stats[:days].zero? && energy_stats[:days].zero? && nerve_stats[:days].zero?

    days_tracked = [
      xanax_stats[:days], energy_stats[:days], nerve_stats[:days],
      missions_stats[:days], crimes_stats[:days], activity_stats[:days],
      networth_stats[:days]
    ].max

    xanax_daily = xanax_stats[:daily]
    energy_refills_daily = energy_stats[:daily]
    nerve_refills_daily = nerve_stats[:daily]
    missions_daily = missions_stats[:daily]
    crimes_daily = crimes_stats[:daily]
    activity_time_daily = activity_stats[:days] > 0 ? (activity_stats[:gained].to_f / 60 / activity_stats[:days]).round(0) : 0

    ssl_user = user.ssl_user?
    xanax_compliance = ssl_user ? :green : stat_compliance(xanax_daily, faction.xanax_target)
    energy_compliance = stat_compliance(energy_refills_daily, faction.energy_refill_target)
    nerve_compliance = stat_compliance(nerve_refills_daily, faction.nerve_refill_target)

    compliance_level = member_compliance_level(xanax_compliance, energy_compliance, nerve_compliance)
    score = ssl_user ? compliance_score_ssl(energy_refills_daily, nerve_refills_daily, faction) : compliance_score(xanax_daily, energy_refills_daily, nerve_refills_daily, faction)

    {
      torn_id: user.torn_id,
      name: user.name,
      ssl_user: ssl_user,
      compliance_level: compliance_level,
      compliance_score: score,

      xanax_gained: xanax_stats[:gained],
      xanax_daily: xanax_daily,
      xanax_compliance: xanax_compliance,

      energy_refills_gained: energy_stats[:gained],
      energy_refills_daily: energy_refills_daily,
      energy_refills_compliance: energy_compliance,

      nerve_refills_gained: nerve_stats[:gained],
      nerve_refills_daily: nerve_refills_daily,
      nerve_refills_compliance: nerve_compliance,

      missions_gained: missions_stats[:gained],
      missions_daily: missions_daily,

      crimes_gained: crimes_stats[:gained],
      crimes_daily: crimes_daily,

      activity_time_gained: activity_stats[:gained],
      activity_time_daily: activity_time_daily,

      networth_gained: networth_stats[:gained],
      networth_current: networth_stats[:current],

      days_tracked: days_tracked
    }
  end

  def calculate_stat(snapshots, field)
    relevant = snapshots.select { |s| s[field].present? }
    return { gained: 0, daily: 0.0, days: 0, current: 0 } if relevant.size < 2

    first = relevant.first
    last = relevant.last
    gained = (last[field] || 0) - (first[field] || 0)

    actual_days = (last.date - first.date).to_i
    daily = actual_days > 0 ? (gained.to_f / actual_days).round(2) : 0.0

    { gained: gained, daily: daily, days: actual_days, current: last[field] || 0 }
  end
end
