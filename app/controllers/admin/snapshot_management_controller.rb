module Admin
  class SnapshotManagementController < ApplicationController
    before_action :require_admin

    # Seconds per API call (polling_interval of torn_api queue)
    SECONDS_PER_API_CALL = 1.1

    def index
      @users_with_gaps = users_with_missing_snapshots
      @summary = calculate_summary
    end

    def backfill_user
      user = User.find(params[:id])
      missing_dates = missing_dates_for_user(user)

      # Count jobs already in the torn_api queue (not yet finished)
      existing_queued_jobs = SolidQueue::Job.where(queue_name: "torn_api", finished_at: nil).count

      missing_dates.each_with_index do |date, index|
        BackfillSingleStatJob.set(wait: index.seconds).perform_later(user.id, date.to_s)
      end

      # Each BackfillSingleStatJob triggers 2 API calls (batch 1 + batch 2)
      # Total API calls = existing jobs + (new jobs * 2)
      total_api_calls = existing_queued_jobs + (missing_dates.size * 2)
      estimated_seconds = (total_api_calls * SECONDS_PER_API_CALL).ceil

      user.update!(backfill_ends_at: Time.current + estimated_seconds.seconds)

      render json: { success: true, message: "Scheduled #{missing_dates.size * 2} API calls for #{user.name} (~#{estimated_seconds}s)" }
    end

    private

    def users_with_missing_snapshots
      tracked_user_ids = User.tracked_for_stats.pluck(:id)
      return [] if tracked_user_ids.empty?

      existing_snapshots = PersonalStatSnapshot
        .where(user_id: tracked_user_ids)
        .pluck(:user_id, :date)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).to_set }

      expected_dates = expected_date_range.to_a

      users_data = User.tracked_for_stats.includes(:faction).filter_map do |user|
        # Skip users with backfill in progress
        next if user.backfill_in_progress?

        user_snapshots = existing_snapshots[user.id] || Set.new
        missing = expected_dates - user_snapshots.to_a

        next if missing.empty?

        {
          user: user,
          missing_count: missing.size,
          missing_dates: missing.sort.reverse,
          latest_snapshot: user_snapshots.max,
          oldest_missing: missing.min
        }
      end

      users_data.sort_by { |u| -u[:missing_count] }
    end

    def missing_dates_for_user(user)
      existing = user.personal_stat_snapshots.pluck(:date).to_set
      expected_date_range.to_a - existing.to_a
    end

    def expected_date_range
      PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date
    end

    def calculate_summary
      tracked_count = User.tracked_for_stats.count
      date_range = expected_date_range
      total_expected = tracked_count * date_range.count
      total_existing = PersonalStatSnapshot
        .where(user_id: User.tracked_for_stats.select(:id))
        .where(date: date_range)
        .count

      {
        tracked_users: tracked_count,
        total_expected: total_expected,
        total_existing: total_existing,
        total_missing: total_expected - total_existing,
        coverage_percent: total_expected > 0 ? ((total_existing.to_f / total_expected) * 100).round(1) : 0
      }
    end
  end
end
