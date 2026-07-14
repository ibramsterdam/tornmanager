# Shared by the nightly sync jobs: re-fetch missing snapshot dates, capped so
# one user with a long history can't dump hundreds of API calls onto a single
# key in one night. Newest gaps first — recent data is the valuable data, and
# older gaps fill on later nights.
module GapBackfill
  BACKFILL_GAP_LIMIT = 30

  private

  def backfill_gaps(user, api_key)
    window_start = PersonalStatSnapshot.tracking_start_date
    window_end = PersonalStatSnapshot.tracking_end_date
    existing = user.personal_stat_snapshots.pluck(:date).to_set
    partial = user.personal_stat_snapshots.partial.where(date: window_start..window_end).pluck(:date)
    yesterday = Date.current.yesterday

    missing = (window_start..window_end).reject { |d| existing.include?(d) || d == yesterday }
    targets = (missing + partial.reject { |d| d == yesterday }).uniq.sort
    return if targets.empty?

    targets.last(BACKFILL_GAP_LIMIT).each do |date|
      BackfillSingleStatJob.perform_later(user.id, date.to_s, faction_id: user.faction_id, api_key: api_key)
    end
  end
end
