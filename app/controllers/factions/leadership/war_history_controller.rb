class Factions::Leadership::WarHistoryController < Factions::Leadership::BaseController
  REFRESH_COOLDOWN = 60.seconds

  def show
    load_wars_data
    load_refresh_state
  end

  def refresh
    if refresh_on_cooldown?
      return redirect_to faction_leadership_war_history_path(@faction), alert: "Please wait before refreshing again."
    end

    Rails.cache.write(refresh_cache_key, Time.current, expires_in: REFRESH_COOLDOWN)

    api_key = @faction.torn_api_key&.key
    if api_key.present?
      BackfillRankedWarsJob.perform_now(@faction.id)
    end

    load_wars_data
    load_refresh_state

    render :show
  end

  private

  def load_refresh_state
    @can_refresh = !refresh_on_cooldown?
    @refresh_seconds_remaining = refresh_seconds_remaining
  end

  def refresh_cache_key
    "faction:#{@faction.id}:war_history_refresh"
  end

  def refresh_on_cooldown?
    Rails.cache.read(refresh_cache_key).present?
  end

  def refresh_seconds_remaining
    last_refresh = Rails.cache.read(refresh_cache_key)
    return 0 unless last_refresh

    remaining = REFRESH_COOLDOWN - (Time.current - last_refresh)
    [ remaining.to_i, 0 ].max
  end
end
