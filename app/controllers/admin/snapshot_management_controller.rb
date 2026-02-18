module Admin
  class SnapshotManagementController < ApplicationController
    before_action :require_admin

    def index
      @users_with_gaps = users_with_missing_snapshots
      @summary = calculate_summary
    end

    def backfill_user
      user = User.find(params[:id])
      missing_dates = missing_dates_for_user(user)

      missing_dates.each_with_index do |date, index|
        BackfillSingleStatJob.set(wait: index.seconds).perform_later(user.id, date.to_s)
      end

      redirect_to admin_snapshot_management_index_path,
        notice: "Scheduled #{missing_dates.size} backfill jobs for #{user.name}"
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

      users_data = User.tracked_for_stats.includes(:faction).map do |user|
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
      end.compact

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
