require "test_helper"

class Elimination::DemoTest < ActiveSupport::TestCase
  class RecordingNotifier
    attr_reader :events

    def initialize
      @events = []
    end

    def method_missing(name, *args)
      @events << name
      "msg-#{@events.size}"
    end

    def respond_to_missing?(*)
      true
    end
  end

  setup do
    @setting = EliminationSetting.create!
    @notifier = RecordingNotifier.new
    @demo = Elimination::Demo.new(@setting, notifier: @notifier)
  end

  test "every kind dispatches to the notifier" do
    Elimination::Demo::KINDS.each { |kind| @demo.send!(kind) }

    assert_includes @notifier.events, :push_started
    assert_includes @notifier.events, :push_resolved
    assert_includes @notifier.events, :countdown_started
    assert_includes @notifier.events, :tick_report
    assert_includes @notifier.events, :team_eliminated
    assert_includes @notifier.events, :standings
    assert_includes @notifier.events, :health_down
    assert_includes @notifier.events, :health_recovered
  end

  test "rejects unknown kinds" do
    assert_raises(ArgumentError) { @demo.send!("everything") }
  end

  test "demo standings render a full embed" do
    embed = Elimination::Notifier.new(@setting).standings_embed(@demo.send(:teams))

    assert_includes embed[:description], "Reptilians"
    assert_includes embed[:description], "eliminated"
    assert embed[:fields].any? { |field| field[:name] == "Cushion (last)" }
  end
end
