module TornApi
  # Client-side request budget, enforced before any HTTP happens. Torn allows
  # 100 requests/minute per player across all their keys; we budget half per
  # key plus a global cap per server IP, shared across processes via Rails.cache.
  class RateLimiter
    TORN_HARD_LIMIT = 100
    REQUESTS_PER_MINUTE = TORN_HARD_LIMIT / 2
    GLOBAL_REQUESTS_PER_MINUTE = 300
    WINDOW_SECONDS = 60

    # Background jobs leave the top 15% of each key's budget for live web traffic.
    BACKGROUND_RESERVE = 0.15
    BACKGROUND_REQUESTS_PER_MINUTE = (REQUESTS_PER_MINUTE * (1 - BACKGROUND_RESERVE)).floor

    class << self
      def reserving_headroom_for_live_traffic
        prior = Thread.current[:torn_api_reserve_headroom]
        Thread.current[:torn_api_reserve_headroom] = true
        yield
      ensure
        Thread.current[:torn_api_reserve_headroom] = prior
      end

      def acquire!(api_key)
        limit = reserving_headroom? ? BACKGROUND_REQUESTS_PER_MINUTE : REQUESTS_PER_MINUTE

        key_count = increment(key_window(api_key))
        if key_count > limit
          raise RateLimitError, "Too many requests (client-side key budget of #{limit}/min spent)"
        end

        global_count = increment(global_window)
        if global_count > GLOBAL_REQUESTS_PER_MINUTE
          raise RateLimitError, "Too many requests (client-side global budget of #{GLOBAL_REQUESTS_PER_MINUTE}/min spent)"
        end

        true
      end

      def remaining(api_key)
        [ REQUESTS_PER_MINUTE - current(key_window(api_key)), 0 ].max
      end

      private

      def reserving_headroom?
        Thread.current[:torn_api_reserve_headroom] == true
      end

      # Null cache stores (test default) return nil; treat as unlimited.
      def increment(cache_key)
        Rails.cache.increment(cache_key, 1, expires_in: WINDOW_SECONDS * 2) || 1
      end

      def current(cache_key)
        Rails.cache.read(cache_key, raw: true).to_i
      end

      def key_window(api_key)
        "torn_api_budget:#{window_stamp}:#{api_key}"
      end

      def global_window
        "torn_api_budget:#{window_stamp}:global"
      end

      def window_stamp
        Time.current.to_i / WINDOW_SECONDS
      end
    end
  end
end
