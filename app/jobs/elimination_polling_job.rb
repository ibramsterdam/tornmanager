class EliminationPollingJob < ApplicationJob
  SNAPSHOT_EVERY = 60.seconds
  SNAPSHOT_CACHE_KEY = "elimination:last_snapshot_at".freeze
  HEALTH_CACHE_KEY = "elimination:health".freeze
  FAILURES_BEFORE_WARNING = 5

  queue_as :war
  limits_concurrency to: 1, key: "elimination_polling"

  def perform
    setting = EliminationSetting.current
    return unless setting.polling_active?

    begin
      teams = TornApi::Torn::Elimination.new(setting.polling_api_key).fetch
      Elimination::Tracker.new(setting).process(teams)
      persist_snapshot(teams)
      record_success(setting)
    rescue TornApi::InvalidKeyError => e
      Rails.logger.error("EliminationPollingJob: invalid API key, stopping (#{e.message})")
      setting.update!(polling_active: false, last_error: e.message)
    rescue StandardError => e
      Rails.logger.error("EliminationPollingJob: #{e.class} - #{e.message}")
      record_failure(setting, e)
    end

    reschedule(setting)
  end

  private

  def persist_snapshot(teams)
    last_at = Rails.cache.read(SNAPSHOT_CACHE_KEY)
    return if last_at && Time.current - last_at < SNAPSHOT_EVERY

    EliminationSnapshot.record_teams(teams)
    Rails.cache.write(SNAPSHOT_CACHE_KEY, Time.current)
  end

  def record_success(setting)
    setting.update_columns(last_polled_at: Time.current, last_error: nil)

    health = Rails.cache.read(HEALTH_CACHE_KEY)
    return unless health

    Elimination::Notifier.new(setting).health_recovered if health[:warned]
    Rails.cache.delete(HEALTH_CACHE_KEY)
  end

  def record_failure(setting, error)
    setting.update_columns(last_error: "#{error.class}: #{error.message}".truncate(255))

    health = Rails.cache.read(HEALTH_CACHE_KEY) || { failures: 0, warned: false, failing_since: Time.current }
    health[:failures] += 1

    if health[:failures] >= FAILURES_BEFORE_WARNING && !health[:warned]
      Elimination::Notifier.new(setting).health_down(failing_since: health[:failing_since])
      health[:warned] = true
    end

    Rails.cache.write(HEALTH_CACHE_KEY, health, expires_in: 1.hour)
  end

  def reschedule(setting)
    return unless setting.reload.polling_active?

    self.class.set(wait: setting.poll_interval_seconds.seconds).perform_later
  end
end
