module TornApi
  # Client-side budget for Torn API calls, enforced in TornApi::Base#get
  # before any HTTP happens — a rejected call must not cost a real request,
  # since Torn counts rejected requests toward its own limit.
  #
  # Torn's hard limit is 100 requests/minute per player across all their
  # keys. We take half per key, leaving headroom for the key owner's own
  # usage (YATA, Torn PDA, browsing) that we can't see. The global budget
  # caps what this server's IP sends in total — Torn documents no aggregate
  # limit, but error code 8 ("IP blocked for abuse") exists.
  #
  # Counters live in Rails.cache (solid_cache in production) so web requests
  # and every job worker process draw from the same budget. Fixed 60-second
  # windows: worst case in any rolling minute is 2x the budget, which is why
  # the per-key budget must stay at half the hard limit.
  class RateLimiter
    TORN_HARD_LIMIT = 100
    REQUESTS_PER_MINUTE = TORN_HARD_LIMIT / 2
    GLOBAL_REQUESTS_PER_MINUTE = 300
    WINDOW_SECONDS = 60

    # Background jobs (nightly fetches, backfills, activity polls) yield the top
    # slice of each key's budget to the key owner's live web traffic: they stop
    # at 85% of the per-key budget so the remaining ~15% stays available for
    # interactive requests, which aren't paced or serialized and would otherwise
    # be starved whenever a signup backfill is saturating that key. Web requests
    # run outside background mode and may use the full per-key budget.
    BACKGROUND_RESERVE = 0.15
    BACKGROUND_REQUESTS_PER_MINUTE = (REQUESTS_PER_MINUTE * (1 - BACKGROUND_RESERVE)).floor

    class << self
      # Runs the block in background mode — acquire! applies the reduced budget
      # that reserves headroom for live traffic. Reentrant and thread-scoped so
      # it's safe across the shared job worker pool.
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

      # Null cache stores (test default) return nil from increment; treat as
      # unlimited rather than blocking every call.
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
