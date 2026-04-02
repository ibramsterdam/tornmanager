module Admin
  class StatsController < ApplicationController
    before_action :require_admin

    def index
      load_user_stats
      load_faction_stats
      load_snapshot_stats
      load_activity_stats
      load_data_health
      load_api_stats
      load_sign_in_stats
    end

    private

    def load_user_stats
      @total_users = User.count
      @tracked_users = User.tracked_for_stats.count
      @active_subscribers = User.active_subscribers.count
      @hof_stats_users = User.hof_stats_users.count
      @api_keys_configured = User.where.not(api_key: nil).count
    end

    def load_faction_stats
      @total_factions = Faction.count
      @factions_with_backfill = Faction.where("backfill_ends_at > ?", Time.current).count
      @faction_stats = Faction.left_joins(:users).group("factions.id", "factions.name").count("users.id")
    end

    def load_snapshot_stats
      @total_snapshots = PersonalStatSnapshot.count
      @earliest_snapshot = PersonalStatSnapshot.minimum(:timestamp)
      @latest_snapshot = PersonalStatSnapshot.maximum(:timestamp)
      @unique_snapshot_days = PersonalStatSnapshot.distinct.pluck(Arel.sql("DATE(timestamp, 'unixepoch')")).count
    end

    def load_activity_stats
      today_start = Time.current.beginning_of_day.to_i
      week_start = 7.days.ago.beginning_of_day.to_i

      @snapshots_today = PersonalStatSnapshot.where("timestamp >= ?", today_start).count
      @snapshots_this_week = PersonalStatSnapshot.where("timestamp >= ?", week_start).count
      @api_calls_today = ApiCall.where("created_at >= ?", Time.current.beginning_of_day).count
      @api_calls_this_week = ApiCall.where("created_at >= ?", 7.days.ago.beginning_of_day).count

      @daily_snapshots = PersonalStatSnapshot
        .where("timestamp >= ?", week_start)
        .group(Arel.sql("DATE(timestamp, 'unixepoch')"))
        .count
        .sort_by { |date, _| date }
        .last(7)
    end

    def load_data_health
      users_with_yesterday_snapshot = PersonalStatSnapshot
        .where(date: Date.yesterday)
        .distinct
        .pluck(:user_id)
      @users_missing_yesterday = User.tracked_for_stats.where.not(id: users_with_yesterday_snapshot).count

      calculate_snapshot_gaps

      @complete_snapshots = PersonalStatSnapshot
        .where.not(
          drugs_xanax: nil, items_used_energy_drinks: nil, other_refills_energy: nil,
          other_refills_nerve: nil, items_used_boosters: nil, items_used_stat_enhancers: nil,
          missions_contracts_total: nil, crimes_offenses_total: nil, other_activity_time: nil,
          networth_total: nil, attacking_networth_money_mugged: nil
        )
        .count
      @incomplete_snapshots = @total_snapshots - @complete_snapshots
    end

    def load_api_stats
      @total_api_calls = ApiCall.count
      @api_peak_rate_all_time = peak_rate(ApiCall.all)
      @api_peak_rate_today = peak_rate(ApiCall.today)

      admin_calls = ApiCall.where(api_key: AdminCredentials.api_key)
      @admin_api_total = admin_calls.count
      @admin_api_peak_all_time = peak_rate(admin_calls)
      @admin_api_peak_today = peak_rate(admin_calls.today)
    end

    def peak_rate(scope)
      scope
        .group(ApiCall::MINUTE_BUCKET)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(1)
        .pick(Arel.sql("COUNT(*)")) || 0
    end

    def load_sign_in_stats
      week_ago = 7.days.ago

      @sign_ins_this_week = Session.where("created_at >= ?", week_ago).count
      @unique_sign_ins_this_week = Session.where("created_at >= ?", week_ago).distinct.count(:user_id)

      first_session_dates = Session
        .group(:user_id)
        .minimum(:created_at)
        .select { |_, first_at| first_at >= week_ago }

      @first_session_dates = first_session_dates
      @new_sign_ins = User.where(id: first_session_dates.keys).order(created_at: :desc)
    end

    def calculate_snapshot_gaps
      tracked_user_ids = User.tracked_for_stats.pluck(:id)
      return set_empty_gap_stats if tracked_user_ids.empty?

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
