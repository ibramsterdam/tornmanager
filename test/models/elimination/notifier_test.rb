require "test_helper"

class Elimination::NotifierTest < ActiveSupport::TestCase
  setup do
    @setting = EliminationSetting.create!(
      alerts_webhook_url: "https://discord.com/api/webhooks/1/a"
    )
    @notifier = Elimination::Notifier.new(@setting)
  end

  test "push on our team carries the alert text without any mention" do
    push = our_push
    Discord::Webhook.any_instance.expects(:post).with do |args|
      args[:content] == "we are getting pushed!" &&
        args[:embed][:title] == "🚨 Push on Conspiracy Theorists" &&
        args[:allowed_mentions].nil?
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

  test "tick report for our loss carries the alert text" do
    Discord::Webhook.any_instance.expects(:post).with do |args|
      args[:content] == "we lost a life"
    end.returns("113")

    @notifier.tick_report(
      ours: true, loser_name: "Conspiracy Theorists", loser_lives: 47,
      tick_at: Time.current, our_rank: 11, our_tickets: 400, our_lives: 47,
      bottom: [ [ "Conspiracy Theorists", 400 ], [ "Brain Surgeons", 564 ] ], cushion: 0
    )
  end

  test "standings embed colors our row green and the bottom row red" do
    teams = [
      team(86, "APEX", tickets: 2118),
      team(80, "Conspiracy Theorists", tickets: 1298),
      team(89, "Brain Surgeons", tickets: 488),
      team(82, "Gold Dust", tickets: 0, eliminated: true)
    ]

    embed = @notifier.standings_embed(teams)

    assert embed[:description].start_with?("```diff")
    lines = embed[:description].lines
    assert lines[2].start_with?("  1"), lines[2]
    assert lines[3].start_with?("+ 2  Conspiracy Theorists"), lines[3]
    assert lines[4].start_with?("- 3  Brain Surgeons"), lines[4]
    assert_includes lines[5], "eliminated"
  end

  test "standings embed carries cushion, gap up, and next tick" do
    teams = [
      team(86, "APEX", tickets: 2118),
      team(80, "Conspiracy Theorists", tickets: 1298),
      team(89, "Brain Surgeons", tickets: 488)
    ]

    embed = @notifier.standings_embed(teams)

    fields = embed[:fields].index_by { |field| field[:name] }
    assert_equal "+810", fields["Cushion (last)"][:value]
    assert_equal "820", fields["Gap up (1st)"][:value]
    assert fields.key?("Next tick") || fields.key?("Life ticks from")
  end

  test "posts through the bot when a token and channel are configured" do
    @setting.update!(alerts_channel_id: "555")
    Rails.application.credentials.stubs(:dig).with(:cia_bot, :bot_token).returns("bot_token")
    Discord::BotChannel.any_instance.expects(:post).returns("221")
    Discord::Webhook.any_instance.expects(:post).never

    assert_equal "221", @notifier.push_started(our_push)
  end

  test "falls back to the webhook without a bot token" do
    @setting.update!(alerts_channel_id: "555")
    Rails.application.credentials.stubs(:dig).with(:cia_bot, :bot_token).returns(nil)
    Discord::Webhook.any_instance.expects(:post).returns("222")

    assert_equal "222", @notifier.push_started(our_push)
  end

  test "resolving our push replaces the ping text" do
    Discord::Webhook.any_instance.expects(:edit).with do |message_id, args|
      message_id == "111" && args[:content] == "we weathered the push ✅" &&
        args[:embed][:title] == "✅ Push on Conspiracy Theorists over"
    end.returns(true)

    @notifier.push_resolved("111",
      ours: true, team_name: "Conspiracy Theorists", started_at: 8.minutes.ago,
      tickets_before: 1384, tickets_now: 1298, net_loss: 86, cushion: 810)
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
