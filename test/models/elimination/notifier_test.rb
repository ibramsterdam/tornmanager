require "test_helper"

class Elimination::NotifierTest < ActiveSupport::TestCase
  setup do
    @setting = EliminationSetting.create!(
      alerts_webhook_url: "https://discord.com/api/webhooks/1/a",
      role_id: "424242"
    )
    @notifier = Elimination::Notifier.new(@setting)
  end

  test "push on our team pings the role" do
    push = our_push
    Discord::Webhook.any_instance.expects(:post).with do |args|
      args[:content] == "<@&424242> we are getting pushed!" &&
        args[:embed][:title] == "🚨 Push on Conspiracy Theorists" &&
        args[:allowed_mentions] == { parse: [], roles: [ "424242" ] }
    end.returns("111")

    assert_equal "111", @notifier.push_started(push)
  end

  test "push on another team posts without a ping" do
    push = our_push.merge(ours: false, team_name: "Brain Surgeons")
    Discord::Webhook.any_instance.expects(:post).with do |args|
      args[:content].nil? && args[:embed][:title] == "🚨 Push on Brain Surgeons"
    end.returns("112")

    @notifier.push_started(push)
  end

  test "push embed reports the window loss and attackers" do
    embed = @notifier.push_embed(our_push)

    assert_includes embed[:description], "14 tickets in 10 seconds"
    attackers = embed[:fields].find { |f| f[:name] == "Likely attackers" }
    assert_includes attackers[:value], "Reptilians (wins +11)"
  end

  test "countdown embed names the team to pass and the exact gap" do
    embed = @notifier.countdown_embed(
      rank: 11, total_alive: 11, gap: 55, escape_team: "Inanimate Objects",
      escape_tickets: 1186, our_tickets: 1131, tick_at: Time.current + 12.minutes
    )

    assert_includes embed[:title], "we are LAST"
    assert_includes embed[:description], "+56 tickets"
    assert_includes embed[:description], "Inanimate Objects"
  end

  test "tick report for our loss uses the ping" do
    Discord::Webhook.any_instance.expects(:post).with do |args|
      args[:content] == "<@&424242> we lost a life"
    end.returns("113")

    @notifier.tick_report(
      ours: true, loser_name: "Conspiracy Theorists", loser_lives: 47,
      tick_at: Time.current, our_rank: 11, our_tickets: 400, our_lives: 47,
      bottom: [ [ "Conspiracy Theorists", 400 ], [ "Brain Surgeons", 564 ] ], cushion: 0
    )
  end

  test "standings embed sorts by tickets and marks our team" do
    teams = [
      team(86, "APEX", tickets: 2118),
      team(80, "Conspiracy Theorists", tickets: 1298),
      team(82, "Gold Dust", tickets: 0, eliminated: true)
    ]

    embed = @notifier.standings_embed(teams)

    lines = embed[:description].lines
    assert_includes lines[1], "APEX"
    assert_includes lines[2], "▸ 2  Conspiracy Theorists"
    assert_includes lines[3], "Gold Dust"
    assert_includes lines[3], "eliminated"
  end

  test "no ping without a configured role" do
    @setting.update!(role_id: nil)
    Discord::Webhook.any_instance.expects(:post).with do |args|
      args[:content] == "we are getting pushed!" && args[:allowed_mentions].nil?
    end.returns("114")

    @notifier.push_started(our_push)
  end

  private

  def our_push
    {
      ours: true, team_name: "Conspiracy Theorists", lost: 14, window_seconds: 10,
      tickets_before: 1384, tickets_now: 1370, pace_per_minute: 84, cushion: 806,
      next_tick_at: Time.current + 7.minutes, attackers: [ [ "Reptilians", 11 ], [ "APEX", 3 ] ]
    }
  end

  def team(torn_id, name, tickets:, lives: 50, eliminated: false)
    TornApi::Torn::Elimination::Team.new(torn_id, name, 2027, 0, tickets, lives, 5000, 4000, eliminated, nil)
  end
end
