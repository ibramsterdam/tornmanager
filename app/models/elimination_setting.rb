class EliminationSetting < ApplicationRecord
  NOTIFICATIONS = [
    { key: "push_ours", label: "Push on us", demos: %w[push_ours push_resolved] },
    { key: "push_rivals", label: "Push on other teams", demos: %w[push_rival] },
    { key: "countdown", label: "Life tick countdown", demos: %w[countdown], live: true },
    { key: "ticks", label: "Life tick reports", demos: %w[tick_other tick_ours] },
    { key: "eliminations", label: "Eliminations", demos: %w[elimination] },
    { key: "standings", label: "Standings", demos: %w[standings], live: true },
    { key: "health", label: "API health", demos: %w[health_down health_recovered] }
  ].freeze

  validates :team_name, presence: true
  validates :poll_interval_seconds, :push_window_seconds, :push_ticket_threshold,
    :push_resolve_seconds, :countdown_bottom_ranks, :standings_interval_minutes,
    numericality: { only_integer: true, greater_than: 0 }

  def self.current
    first || create!
  end

  def polling_api_key
    api_key.presence || AdminCredentials.api_key
  end

  def start_polling!
    update!(polling_active: true, last_error: nil)
    Elimination::Tracker.reset!
    EliminationPollingJob.perform_later
  end

  def stop_polling!
    update!(polling_active: false)
  end

  def life_ticks_active?(at = Time.current)
    at >= life_ticks_from
  end
end
