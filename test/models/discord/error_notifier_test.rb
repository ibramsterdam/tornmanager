require "test_helper"

class Discord::ErrorNotifierTest < ActiveSupport::TestCase
  test "includes environment field" do
    error = StandardError.new("test error")
    error.set_backtrace([ "#{Rails.root}/app/models/user.rb:10:in `save'" ])

    Discord::Notifier.expects(:notify).with do |args|
      fields = args[:embed][:fields]
      env_field = fields.find { |f| f[:name] == "Environment" }
      env_field[:value] == "test"
    end

    Discord::ErrorNotifier.new.report(error, handled: false, severity: :error, context: {})
  end

  test "includes app stacktrace" do
    error = StandardError.new("boom")
    error.set_backtrace([
      "#{Rails.root}/app/models/user.rb:10:in `save'",
      "#{Rails.root}/app/controllers/factions_controller.rb:5:in `show'",
      "/gems/actionpack/lib/action_dispatch.rb:100:in `call'"
    ])

    Discord::Notifier.expects(:notify).with do |args|
      fields = args[:embed][:fields]
      trace_field = fields.find { |f| f[:name] == "Stacktrace" }
      trace_field[:value].include?("app/models/user.rb:10") &&
        trace_field[:value].include?("app/controllers/factions_controller.rb:5") &&
        !trace_field[:value].include?("actionpack")
    end

    Discord::ErrorNotifier.new.report(error, handled: false, severity: :error, context: {})
  end

  test "skips stacktrace when no app lines" do
    error = StandardError.new("gem error")
    error.set_backtrace([ "/gems/something/gem_code.rb:10:in `bar'" ])

    Discord::Notifier.expects(:notify).with do |args|
      fields = args[:embed][:fields]
      fields.none? { |f| f[:name] == "Stacktrace" }
    end

    Discord::ErrorNotifier.new.report(error, handled: false, severity: :error, context: {})
  end

  test "skips handled errors" do
    error = StandardError.new("handled")
    Discord::Notifier.expects(:notify).never

    Discord::ErrorNotifier.new.report(error, handled: true, severity: :warning, context: {})
  end

  # During the 04:30 rate-limit incident the reporter posted ~25 identical
  # embeds in one minute. Identical errors within a short window must collapse
  # into a single Discord notification (mirroring the 10-minute dedupe
  # TornApi::Base already applies to its own API-error notifications).

  test "identical errors within the window are reported once" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    error = TornApi::RateLimitError.new("Too many requests")
    Discord::Notifier.expects(:notify).once

    5.times do
      Discord::ErrorNotifier.new.report(error, handled: false, severity: :error, context: {}, source: "application.solid_queue")
    end
  end

  test "different error classes are reported separately" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    Discord::Notifier.expects(:notify).twice

    Discord::ErrorNotifier.new.report(TornApi::RateLimitError.new("Too many requests"), handled: false, severity: :error, context: {}, source: "application.solid_queue")
    Discord::ErrorNotifier.new.report(TornApi::ApiError.new("Too many requests"), handled: false, severity: :error, context: {}, source: "application.solid_queue")
  end

  test "the same error is reported again after the window expires" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    error = TornApi::RateLimitError.new("Too many requests")
    Discord::Notifier.expects(:notify).twice

    Discord::ErrorNotifier.new.report(error, handled: false, severity: :error, context: {}, source: "application.solid_queue")
    travel 11.minutes do
      Discord::ErrorNotifier.new.report(error, handled: false, severity: :error, context: {}, source: "application.solid_queue")
    end
  end
end
