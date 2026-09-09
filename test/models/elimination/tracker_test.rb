require "test_helper"

class Elimination::TrackerTest < ActiveSupport::TestCase
  class RecordingNotifier
    attr_reader :events

    def initialize
      @events = []
    end

    def method_missing(name, *args)
      @events << [ name, args ]
      "msg-#{@events.size}"
    end

    def respond_to_missing?(*)
      true
    end

    def names
      @events.map(&:first)
    end

    def payload(name)
      @events.reverse.find { |event_name, _| event_name == name }&.last&.last
    end
  end

  setup do
    @setting = EliminationSetting.create!
    @notifier = RecordingNotifier.new
    @tracker = Elimination::Tracker.new(@setting, notifier: @notifier)
    @base = Time.utc(2026, 9, 12, 19, 30)
  end

  test "detects a push on our team within the window" do
    with_memory_cache do
      @tracker.process(teams(ours: 1384, apex_wins: 8600), at: @base)
      @tracker.process(teams(ours: 1370, apex_wins: 8611), at: @base + 10)

      assert_includes @notifier.names, :push_started
      push = @notifier.payload(:push_started)
      assert push[:ours]
      assert_equal "Conspiracy Theorists", push[:team_name]
      assert_equal 14, push[:lost]
      assert_equal [ [ "APEX", 11 ] ], push[:attackers]
    end
  end

  test "does not alert under the threshold" do
    with_memory_cache do
      @tracker.process(teams(ours: 1384), at: @base)
      @tracker.process(teams(ours: 1379), at: @base + 10)

      assert_not_includes @notifier.names, :push_started
    end
  end

  test "does not re-alert while a push is running" do
    with_memory_cache do
      @tracker.process(teams(ours: 1384), at: @base)
      @tracker.process(teams(ours: 1370), at: @base + 10)
      @tracker.process(teams(ours: 1355), at: @base + 12)

      assert_equal 1, @notifier.names.count(:push_started)
    end
  end

  test "resolves a quiet push after the resolve window" do
    with_memory_cache do
      @tracker.process(teams(ours: 1384), at: @base)
      @tracker.process(teams(ours: 1370), at: @base + 10)
      @tracker.process(teams(ours: 1370), at: @base + 10 + @setting.push_resolve_seconds)

      assert_includes @notifier.names, :push_resolved
      report = @notifier.payload(:push_resolved)
      assert_equal 14, report[:net_loss]
    end
  end

  test "reports a life tick with our summary" do
    with_memory_cache do
      @tracker.process(teams, at: @base)
      @tracker.process(teams(surgeons_lives: 43), at: @base + 2)

      assert_includes @notifier.names, :tick_report
      tick = @notifier.payload(:tick_report)
      assert_not tick[:ours]
      assert_equal "Brain Surgeons", tick[:loser_name]
      assert_equal 43, tick[:loser_lives]
      assert_equal 2, tick[:our_rank]
    end
  end

  test "reports an elimination once" do
    with_memory_cache do
      @tracker.process(teams, at: @base)
      @tracker.process(teams(surgeons_eliminated: true), at: @base + 2)
      @tracker.process(teams(surgeons_eliminated: true), at: @base + 4)

      assert_equal 1, @notifier.names.count(:team_eliminated)
      assert_equal "Brain Surgeons", @notifier.payload(:team_eliminated)[:name]
    end
  end

  test "starts a countdown when we are last and edits it after 30 seconds" do
    with_memory_cache do
      @tracker.process(teams(ours: 100), at: @base)
      @tracker.process(teams(ours: 100), at: @base + 5)
      @tracker.process(teams(ours: 100), at: @base + 35)

      assert_equal 1, @notifier.names.count(:countdown_started)
      assert_equal 1, @notifier.names.count(:countdown_updated)
      data = @notifier.payload(:countdown_started)
      assert_equal 3, data[:rank]
      assert_equal "Brain Surgeons", data[:escape_team]
      assert_equal 464, data[:gap]
      assert_equal Time.utc(2026, 9, 12, 19, 45), data[:tick_at]
    end
  end

  test "no countdown before life ticks begin" do
    with_memory_cache do
      early = Time.utc(2026, 9, 10, 19, 30)
      @tracker.process(teams(ours: 100), at: early)

      assert_not_includes @notifier.names, :countdown_started
    end
  end

  test "disabled push notifications stay silent but still track state" do
    @setting.update!(notify_push_ours: false)

    with_memory_cache do
      @tracker.process(teams(ours: 1384), at: @base)
      @tracker.process(teams(ours: 1370), at: @base + 10)
      @tracker.process(teams(ours: 1370), at: @base + 10 + @setting.push_resolve_seconds)

      assert_not_includes @notifier.names, :push_started
      assert_not_includes @notifier.names, :push_resolved
    end
  end

  test "disabled toggles silence ticks, eliminations, countdowns, and standings" do
    @setting.update!(notify_ticks: false, notify_eliminations: false, notify_countdown: false, notify_standings: false)

    with_memory_cache do
      @tracker.process(teams(ours: 100), at: @base)
      @tracker.process(teams(ours: 100, surgeons_lives: 43, surgeons_eliminated: true), at: @base + 2)

      assert_empty @notifier.events
    end
  end

  test "posts standings on start and then per interval" do
    with_memory_cache do
      @tracker.process(teams, at: @base)
      @tracker.process(teams, at: @base + 30.minutes)
      @tracker.process(teams, at: @base + 61.minutes)

      assert_equal 2, @notifier.names.count(:standings)
    end
  end

  private

  def teams(ours: 1298, apex_wins: 8600, surgeons_lives: 44, surgeons_eliminated: false)
    [
      team(80, "Conspiracy Theorists", tickets: ours, lives: 48, wins: 7900),
      team(86, "APEX", tickets: 2118, lives: 50, wins: apex_wins),
      team(89, "Brain Surgeons", tickets: 564, lives: surgeons_lives, wins: 5100, eliminated: surgeons_eliminated),
      team(82, "Gold Dust", tickets: 0, lives: 0, wins: 4100, eliminated: true)
    ]
  end

  def team(torn_id, name, tickets:, lives:, wins:, eliminated: false)
    TornApi::Torn::Elimination::Team.new(torn_id, name, 2027, 0, tickets, lives, wins, 5000, eliminated, nil)
  end

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
