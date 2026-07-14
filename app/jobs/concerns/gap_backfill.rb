# Shared by the nightly sync jobs: re-fetch missing snapshot dates, capped so
# one user with a long history can't dump hundreds of API calls onto a single
# key in one night. Newest gaps first — recent data is the valuable data, and
# older gaps fill on later nights.
module GapBackfill
  BACKFILL_GAP_LIMIT = 30

  private

  def backfill_gaps(user, api_key)
    existing = user.personal_stat_snapshots.pluck(:date).to_set
    expected = (PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date).to_a
    yesterday = Date.current.yesterday

    missing = expected.reject { |d| existing.include?(d) || d == yesterday }
    return if missing.empty?

    missing.last(BACKFILL_GAP_LIMIT).each do |date|
      BackfillSingleStatJob.perform_later(user.id, date.to_s, faction_id: user.faction_id, api_key: api_key)
    end
  end
end
