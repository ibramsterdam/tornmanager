class Factions::Leadership::BaseController < ApplicationController
  include FactionAccess

  before_action :require_setup_completed
  before_action :require_faction_leadership
  before_action :require_api_keys_configured

  private

  def require_api_keys_configured
    return if performed?
    find_faction unless @faction
    return if performed?
    return if @faction.faction_setting&.torn_api_key?

    redirect_to setup_faction_leadership_path(@faction)
  end

  def load_wars_data
    @wars = @faction.ranked_wars.recent.includes(:faction)

    current_year_wars = @wars.completed.where(started_at: Date.current.beginning_of_year..)
    @wins = current_year_wars.won.count
    @losses = current_year_wars.lost.count

    @ongoing_war = @wars.ongoing.select(&:in_progress?).first
    @scheduled_war = @wars.ongoing.select(&:scheduled?).first

    @member_performance = calculate_member_performance(current_year_wars)
  end

  def load_spy_stats_data
    @spy_reports = @faction.spy_reports.order(total: :desc)
    @spy_report_count = @spy_reports.count
    @last_import_at = Rails.cache.read(import_cache_key)
    @can_import = @last_import_at.nil?
    @seconds_until_import = seconds_until_import
  end

  def load_settings_data
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
    @torn_api_key_masked = mask_key(@faction_setting.torn_api_key)
    @tornstats_api_key_masked = mask_key(@faction_setting.tornstats_api_key)
    @leadership_users = @faction.leadership.order(:name)
    @faction_members = @faction.users.active.where(leadership_access: false).order(:name)
    @subscription_weeks_remaining = Current.user.subscription_weeks_remaining
    @faction_member_count = @faction.users.active.count
    @war_polling_active = @faction.war_polling_active?
  end

  def load_api_peak_rate
    counts_by_minute = @faction.api_calls
      .today
      .group("strftime('%Y-%m-%d %H:%M', created_at)")
      .count

    @api_peak_rate = counts_by_minute.values.max || 0
  end

  def load_data_coverage
    faction_user_ids = @faction.users.active.pluck(:id)

    if faction_user_ids.empty?
      @data_coverage_rate = 0.0
      @data_missing_yesterday = 0
      @data_total_missing_days = 0
      return
    end

    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date
    expected_days = (start_date..end_date).count

    total_expected = faction_user_ids.size * expected_days
    total_existing = PersonalStatSnapshot
      .where(user_id: faction_user_ids)
      .where(date: start_date..end_date)
      .count

    @data_coverage_rate = total_expected > 0 ? (total_existing.to_f / total_expected * 100).round(1) : 0.0

    yesterday_user_ids = PersonalStatSnapshot
      .where(user_id: faction_user_ids, date: Date.yesterday)
      .distinct
      .pluck(:user_id)
    @data_missing_yesterday = faction_user_ids.size - yesterday_user_ids.size

    @data_total_missing_days = total_expected - total_existing
  end

  def calculate_member_performance(wars)
    return [] if wars.empty?

    performance = {}

    wars.each do |war|
      next unless war.our_members.present?

      war.our_members.each do |member|
        torn_id = member["id"].to_s
        name = member["name"]

        performance[torn_id] ||= {
          name: name,
          torn_id: torn_id,
          wars_participated: 0,
          total_attacks: 0,
          total_score: 0.0
        }

        attacks = member["attacks"].to_i
        if attacks > 0
          performance[torn_id][:wars_participated] += 1
          performance[torn_id][:total_attacks] += attacks
          performance[torn_id][:total_score] += member["score"].to_f
        end
      end
    end

    performance.values.map do |p|
      p[:avg_attacks] = p[:wars_participated] > 0 ? (p[:total_attacks].to_f / p[:wars_participated]).round(1) : 0
      p[:avg_score] = p[:wars_participated] > 0 ? (p[:total_score] / p[:wars_participated]).round(1) : 0
      p[:avg_respect_per_hit] = p[:total_attacks] > 0 ? (p[:total_score] / p[:total_attacks]).round(2) : 0
      p
    end.sort_by { |p| -p[:total_score] }
  end

  def import_cache_key
    "faction:#{@faction.id}:spy_import:last_run"
  end

  def rate_limited?
    Rails.cache.exist?(import_cache_key)
  end

  def seconds_until_import
    last_run = Rails.cache.read(import_cache_key)
    return 0 unless last_run

    remaining = IMPORT_COOLDOWN - (Time.current - last_run)
    [ remaining.to_i, 0 ].max
  end

  def mask_key(key)
    return nil if key.blank?
    "#{key[0..3]}********#{key[-4..]}"
  end

  IMPORT_COOLDOWN = 1.minute
end
