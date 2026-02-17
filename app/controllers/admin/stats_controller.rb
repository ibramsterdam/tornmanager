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

      # Data health - users missing recent snapshots
      yesterday_start = 1.day.ago.beginning_of_day.to_i
      yesterday_end = 1.day.ago.end_of_day.to_i
      users_with_yesterday_snapshot = PersonalStatSnapshot
        .where(timestamp: yesterday_start..yesterday_end)
        .distinct
        .pluck(:user_id)
      @users_missing_yesterday = User.tracked_for_stats.where.not(id: users_with_yesterday_snapshot).count

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
  end
end
