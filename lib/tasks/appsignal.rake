namespace :appsignal do
  desc "Generate fake metrics for testing AppSignal dashboard"
  task test_metrics: :environment do
    puts "Generating fake AppSignal metrics..."

    # Torn API metrics
    10.times do
      response_time = rand(50..500)
      Appsignal.add_distribution_value("torn_api.response_time", response_time)
      Appsignal.increment_counter("torn_api.requests", 1, { status: "success", endpoint: "user" })
    end
    2.times do
      Appsignal.increment_counter("torn_api.requests", 1, { status: "error", endpoint: "user", error_type: "TimeoutError" })
    end
    Appsignal.increment_counter("torn_api.rate_limit", 1)
    Appsignal.increment_counter("torn_api.invalid_key", 1)
    Appsignal.increment_counter("torn_api.retries", 1, { reason: "timeout" })
    puts "  - Torn API metrics sent"

    # Auth metrics
    5.times { Appsignal.increment_counter("auth.login_success", 1) }
    Appsignal.increment_counter("auth.login_failed", 1, { reason: "invalid_key" })
    Appsignal.increment_counter("auth.login_failed", 1, { reason: "wrong_key_type" })
    Appsignal.increment_counter("auth.login_failed", 1, { reason: "profile_fetch_failed" })
    Appsignal.increment_counter("auth.logout", 1)
    puts "  - Auth metrics sent"

    # Subscription metrics
    3.times { Appsignal.increment_counter("subscription.xanax_payment", 1) }
    Appsignal.increment_counter("subscription.weeks_granted", 5, { type: "xanax" })
    Appsignal.increment_counter("subscription.weeks_granted", 20, { type: "faction_grant" })
    Appsignal.increment_counter("subscription.faction_grant", 1)
    Appsignal.increment_counter("subscription.users_granted", 15)
    Appsignal.increment_counter("subscription.manual_refresh", 2)
    Appsignal.increment_counter("subscription.refresh_failed", 1)
    Appsignal.increment_counter("subscription.days_updated", 1)
    puts "  - Subscription metrics sent"

    # Job metrics
    20.times { Appsignal.increment_counter("jobs.personal_stats_fetched", 1) }
    2.times { Appsignal.increment_counter("jobs.personal_stats_failed", 1) }
    Appsignal.set_gauge("jobs.personal_stats_scheduled", 150)
    puts "  - Job metrics sent"

    # User metrics
    Appsignal.increment_counter("user.data_purged", 1)
    puts "  - User metrics sent"

    puts "\nDone! Check AppSignal in a few minutes."
  end
end
