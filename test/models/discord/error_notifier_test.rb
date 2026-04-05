require "test_helper"

class Discord::ErrorNotifierTest < ActiveSupport::TestCase
  test "includes environment field" do
    error = StandardError.new("test error")
    error.set_backtrace([ "app/models/user.rb:10:in `save'" ])

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
      "/home/deploy/app/models/user.rb:10:in `save'",
      "/home/deploy/app/controllers/factions_controller.rb:5:in `show'",
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
end
