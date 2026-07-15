module Admin
  class StatsController < ApplicationController
    before_action :require_admin

    def index
      load_user_stats
      load_subscription_stats
      load_faction_stats
      load_snapshot_stats
      load_activity_stats
      load_data_health
      load_api_stats
      load_sign_in_stats
      load_armory_stats
      load_pipeline_stats
    end

    private

    def load_user_stats
      @total_users = User.count
      @tracked_users = User.tracked_for_stats.count
      @active_subscribers = User.active_subscribers.count
      @hof_stats_users = User.hof_stats_users.count
      @api_keys_configured = ApiKey::Torn.where.not(user_id: nil).count
    end

    def load_subscription_stats
      @total_subscribers = Subscription.where("expires_at > ?", Time.current).count
      @subscribed_factions = Faction
        .joins(:subscription)
        .where("subscriptions.expires_at > ?", Time.current)
        .includes(:subscription)
        .order(:name)
      @xanax_received_past_month = XanaxPayment
        .where("processed_at >= ?", 1.month.ago)
        .sum(:xanax_amount)
    end

    def load_faction_stats
      @total_factions = Faction.count
      @factions_with_backfill = Faction.where("backfill_ends_at > ?", Time.current).count

      last_sync_by_faction = Rails.cache.fetch("admin_stats:faction_last_sync", expires_in: 15.minutes) do
        MemberActivitySnapshot.group(:faction_id).maximum(:recorded_at)
      end

      details = Faction
        .left_joins(:users)
        .includes(:torn_api_key, :tornstats_api_key)
        .group("factions.id")
        .select("factions.*, COUNT(users.id) as member_count")

      @faction_rows = details.map do |f|
        status, stale_days =
          if f.setup_completed?
            [ :active, nil ]
          elsif f.torn_api_key.blank? && f.updated_at < Faction::STALE_AFTER.ago
            [ :stale, (Date.current - f.updated_at.to_date).to_i ]
          else
            [ :no_setup, nil ]
          end

        {
          faction: f,
          member_count: f.member_count,
          status: status,
          stale_days: stale_days,
          caps: [ f.setup_completed?, f.torn_api_key.present?, f.tornstats_api_key.present?,
                  f.setup_completed? && f.torn_api_key.present?, f.backfill_in_progress? ],
          last_sync: last_sync_by_faction[f.id]
        }
      end.sort_by { |row| [ { active: 0, stale: 1, no_setup: 2 }[row[:status]], -row[:member_count] ] }

      @active_factions = @faction_rows.count { |r| r[:status] == :active }
    end

    def load_snapshot_stats
      @total_snapshots = PersonalStatSnapshot.count
      @earliest_snapshot = PersonalStatSnapshot.minimum(:timestamp)
      @latest_snapshot = PersonalStatSnapshot.maximum(:timestamp)
      @unique_snapshot_days = PersonalStatSnapshot.distinct.count(:date)

      # member_activity_snapshots is millions of rows and grows ~5.7k/day;
      # the distinct counts are full scans, so serve them from cache.
      activity = Rails.cache.fetch("admin_stats:member_activity", expires_in: 15.minutes) do
        {
          total: MemberActivitySnapshot.count,
          polls: MemberActivitySnapshot.distinct.count(:recorded_at),
          members: MemberActivitySnapshot.distinct.count(:torn_member_id),
          earliest: MemberActivitySnapshot.minimum(:recorded_at),
          latest: MemberActivitySnapshot.maximum(:recorded_at)
        }
      end

      @activity_total_snapshots = activity[:total]
      @activity_total_polls = activity[:polls]
      @activity_members_tracked = activity[:members]
      @activity_factions_polled = Faction.where(setup_completed: true).joins(:torn_api_key).count
      @activity_earliest = activity[:earliest]
      @activity_latest = activity[:latest]
      @activity_daily_growth = @activity_total_polls > 0 ? (@activity_total_snapshots / [ @activity_total_polls, 1 ].max) * 96 : 0
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

      @incomplete_snapshots = PersonalStatSnapshot.partial.count
      @tombstoned_snapshots = PersonalStatSnapshot.where(torn_data_missing: true).count
      @complete_snapshots = @total_snapshots - @incomplete_snapshots - @tombstoned_snapshots
      # Tombstoned rows are resolved (Torn has no data to fetch), so they
      # count as accounted-for — otherwise 100% would be unreachable.
      @completeness_pct = @total_snapshots > 0 ? (((@complete_snapshots + @tombstoned_snapshots).to_f / @total_snapshots) * 100).round(1) : nil
    end

    def load_api_stats
      @total_api_calls = ApiCall.count
      @api_peak_rate_all_time = peak_rate(ApiCall.all)
      @api_peak_rate_today = peak_rate(ApiCall.today)

      admin_calls = ApiCall.where(api_key: AdminCredentials.api_key)
      @admin_api_total = admin_calls.count
      @admin_api_peak_all_time = peak_rate(admin_calls)
      @admin_api_peak_today = peak_rate(admin_calls.today)

      # One pass over the 24h window for every key's peak — per-key
      # peak_rate() calls were a full table scan each.
      peak_by_key = Hash.new(0)
      ApiCall.where("created_at > ?", 1.day.ago)
        .group(:api_key, ApiCall::MINUTE_BUCKET)
        .count
        .each do |(key, _bucket), calls|
          peak_by_key[key] = calls if calls > peak_by_key[key]
        end

      @api_key_breakdown = ApiCall.where("created_at > ?", 1.day.ago)
        .group(:api_key)
        .select(
          "api_key",
          "COUNT(*) as total_calls",
          "SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as error_count"
        )
        .order("total_calls DESC")
        .map do |row|
          key = row.api_key
          owner = resolve_key_owner(key)
          {
            key: key,
            display_key: "#{key[0..3]}...#{key[-4..]}",
            owner: owner,
            total: row.total_calls,
            errors: row.error_count,
            peak_rate: peak_by_key[key]
          }
        end

      @per_key_budget = TornApi::RateLimiter::REQUESTS_PER_MINUTE
      @global_budget = TornApi::RateLimiter::GLOBAL_REQUESTS_PER_MINUTE
      @keys_over_budget = @api_key_breakdown.count { |r| r[:peak_rate] > @per_key_budget }
      @api_key_rows, singles = @api_key_breakdown.partition { |r| r[:total] > 1 || r[:errors] > 0 }
      @api_single_call_keys = singles.size
    end

    # Failed/blocked counts live in the solid_queue database; guard so a
    # queue-db hiccup can't take down the stats page.
    def load_pipeline_stats
      @pipeline_stats = {
        failed: SolidQueue::FailedExecution.count,
        blocked: SolidQueue::BlockedExecution.count,
        scheduled: SolidQueue::ScheduledExecution.count
      }
    rescue => e
      Rails.logger.error("[Admin::Stats] pipeline stats unavailable: #{e.message}")
      @pipeline_stats = nil
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

    def load_armory_stats
      @armory_total_entries = ArmoryNewsEntry.count
      @armory_earliest = ArmoryNewsEntry.minimum(:occurred_at)
      @armory_latest = ArmoryNewsEntry.maximum(:occurred_at)

      counts = ArmoryNewsEntry.group(:faction_id).count
      earliest = ArmoryNewsEntry.group(:faction_id).minimum(:occurred_at)
      latest = ArmoryNewsEntry.group(:faction_id).maximum(:occurred_at)

      @armory_by_faction = Faction
        .where(setup_completed: true)
        .includes(:torn_api_key)
        .order(:name)
        .map do |f|
          {
            faction: f,
            count: counts.fetch(f.id, 0),
            earliest: earliest[f.id],
            latest: latest[f.id],
            backfill_pending: f.armory_backfill_pending?
          }
        end
    end

    def resolve_key_owner(key)
      return "Admin" if key == AdminCredentials.api_key
      return "Kaneki (HoF)" if key == Rails.application.credentials.dig(:kaneki, :api_key)

      api_key = ApiKey.find_by(key: key)
      if api_key&.faction
        api_key.faction.name
      elsif api_key&.user
        api_key.user.name
      else
        "Unknown"
      end
    end

    def calculate_snapshot_gaps
      tracked_user_ids = User.tracked_for_stats.pluck(:id)
      return set_empty_gap_stats if tracked_user_ids.empty?

      start_date = PersonalStatSnapshot.tracking_start_date
      end_date = PersonalStatSnapshot.tracking_end_date
      expected_days = (start_date..end_date).count
      window = PersonalStatSnapshot.where(user_id: tracked_user_ids, date: start_date..end_date)

      # Two grouped queries instead of loading every (user_id, date) pair
      # into Ruby.
      days_per_user = window.group(:user_id).distinct.count(:date)
      users_per_date = window.group(:date).distinct.count(:user_id)

      @users_with_gaps = tracked_user_ids.count { |id| days_per_user.fetch(id, 0) < expected_days }
      @total_missing_snapshot_days = tracked_user_ids.sum { |id| expected_days - days_per_user.fetch(id, 0) }
      @missing_dates_summary = (start_date..end_date)
        .map { |date| [ date, tracked_user_ids.size - users_per_date.fetch(date, 0) ] }
        .select { |_, missing| missing.positive? }
        .last(10)
        .reverse
    end

    def set_empty_gap_stats
      @users_with_gaps = 0
      @total_missing_snapshot_days = 0
      @missing_dates_summary = []
    end
  end
end
