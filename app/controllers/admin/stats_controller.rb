module Admin
  class StatsController < ApplicationController
    before_action :require_admin

    def index
      # User counts
      @total_users = User.count
      @tracked_users = User.tracked_for_stats.count
      @active_subscribers = User.active_subscribers.count
      @hof_stats_users = User.hof_stats_users.count

      # Faction overview
      @total_factions = Faction.count
      @tracked_factions = Faction.tracked.count
      @factions_with_backfill = Faction.where("backfill_ends_at > ?", Time.current).count
      @faction_stats = Faction.tracked.left_joins(:users).group("factions.id", "factions.name").count("users.id")

      # Snapshot coverage
      @total_snapshots = PersonalStatSnapshot.count
      @earliest_snapshot = PersonalStatSnapshot.minimum(:timestamp)
      @latest_snapshot = PersonalStatSnapshot.maximum(:timestamp)
      @unique_snapshot_days = PersonalStatSnapshot.distinct.pluck(Arel.sql("DATE(timestamp, 'unixepoch')")).count

      # Recent activity
      today_start = Time.current.beginning_of_day.to_i
      week_start = 7.days.ago.beginning_of_day.to_i
      @snapshots_today = PersonalStatSnapshot.where("timestamp >= ?", today_start).count
      @snapshots_this_week = PersonalStatSnapshot.where("timestamp >= ?", week_start).count
      @api_calls_today = ApiCall.where("created_at >= ?", Time.current.beginning_of_day).count
      @api_calls_this_week = ApiCall.where("created_at >= ?", 7.days.ago.beginning_of_day).count

      # Data health - users missing yesterday's snapshot
      users_with_yesterday_snapshot = PersonalStatSnapshot
        .where(date: Date.yesterday)
        .distinct
        .pluck(:user_id)
      @users_missing_yesterday = User.tracked_for_stats.where.not(id: users_with_yesterday_snapshot).count

      # Data health - snapshot gaps for tracked users
      calculate_snapshot_gaps

      # Snapshot completeness (users with all 11 stats filled)
      @complete_snapshots = PersonalStatSnapshot
        .where.not(
          drugs_xanax: nil,
          drugs_cannabis: nil,
          other_refills_energy: nil,
          other_refills_nerve: nil,
          items_used_boosters: nil,
          items_used_stat_enhancers: nil,
          missions_contracts_total: nil,
          crimes_offenses_total: nil,
          other_activity_time: nil,
          networth_total: nil,
          attacking_networth_money_mugged: nil
        )
        .count
      @incomplete_snapshots = @total_snapshots - @complete_snapshots

      # Recent snapshot activity by day (last 7 days)
      @daily_snapshots = PersonalStatSnapshot
        .where("timestamp >= ?", week_start)
        .group(Arel.sql("DATE(timestamp, 'unixepoch')"))
        .count
        .sort_by { |date, _| date }
        .last(7)
    end

    private

    def calculate_snapshot_gaps
      tracked_user_ids = User.tracked_for_stats.pluck(:id)
      return set_empty_gap_stats if tracked_user_ids.empty?

      # Get all existing snapshot dates per user
      existing_snapshots = PersonalStatSnapshot
        .where(user_id: tracked_user_ids)
        .pluck(:user_id, :date)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).to_set }

      start_date = PersonalStatSnapshot.tracking_start_date
      end_date = PersonalStatSnapshot.tracking_end_date
      expected_dates = (start_date..end_date).to_a

      users_with_gaps = 0
      total_missing = 0
      missing_by_date = Hash.new(0)

      tracked_user_ids.each do |user_id|
        user_snapshots = existing_snapshots[user_id] || Set.new
        missing_dates = expected_dates - user_snapshots.to_a

        if missing_dates.any?
          users_with_gaps += 1
          total_missing += missing_dates.size
          missing_dates.each { |d| missing_by_date[d] += 1 }
        end
      end

      @users_with_gaps = users_with_gaps
      @total_missing_snapshot_days = total_missing
      @missing_dates_summary = missing_by_date.sort_by { |date, _| date }.last(10).reverse
    end

    def set_empty_gap_stats
      @users_with_gaps = 0
      @total_missing_snapshot_days = 0
      @missing_dates_summary = []
    end
  end
end
