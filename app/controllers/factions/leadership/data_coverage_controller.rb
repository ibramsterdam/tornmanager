class Factions::Leadership::DataCoverageController < Factions::Leadership::BaseController
  SECONDS_PER_API_CALL = 1.1

  def show
    load_data_coverage
    load_member_coverage
  end

  def backfill_user
    user = @faction.users.find(params[:user_id])
    missing_dates = missing_dates_for(user)
    api_key = @faction.faction_setting&.torn_api_key

    existing_queued_jobs = SolidQueue::Job.where(queue_name: "faction", finished_at: nil).count

    missing_dates.each_with_index do |date, index|
      BackfillSingleStatJob.set(wait: index.seconds).perform_later(user.id, date.to_s, faction_id: @faction.id, api_key: api_key)
    end

    total_api_calls = existing_queued_jobs + (missing_dates.size * 2)
    estimated_seconds = (total_api_calls * SECONDS_PER_API_CALL).ceil

    user.update!(backfill_ends_at: Time.current + estimated_seconds.seconds)

    render json: { success: true, message: "Scheduled #{missing_dates.size * 2} API calls for #{user.name} (~#{estimated_seconds}s)" }
  end

  private

  def load_member_coverage
    members = @faction.users.active.order(:name)
    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date
    @expected_days = (start_date..end_date).count
    expected_dates = (start_date..end_date).to_a

    existing_snapshots = PersonalStatSnapshot
      .where(user_id: members.pluck(:id))
      .where(date: start_date..end_date)
      .pluck(:user_id, :date)
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last).to_set }

    @member_coverage = members.filter_map do |member|
      user_dates = existing_snapshots[member.id] || Set.new
      existing = user_dates.size
      missing_dates = expected_dates - user_dates.to_a
      next if missing_dates.empty?

      rate = @expected_days > 0 ? (existing.to_f / @expected_days * 100).round(1) : 0.0

      {
        user: member,
        existing: existing,
        missing: missing_dates.size,
        missing_dates: missing_dates.sort,
        rate: rate
      }
    end.sort_by { |m| m[:rate] }

    @tracking_start = start_date
    @tracking_end = end_date
  end

  def missing_dates_for(user)
    existing = user.personal_stat_snapshots.pluck(:date).to_set
    expected = (PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date).to_a
    expected - existing.to_a
  end
end
