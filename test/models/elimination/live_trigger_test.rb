require "test_helper"

class Elimination::LiveTriggerTest < ActiveSupport::TestCase
  setup do
    @setting = EliminationSetting.create!(api_key: "elim_key")
    @notifier = mock
    @trigger = Elimination::LiveTrigger.new(@setting, notifier: @notifier)
  end

  test "standings sends the live table" do
    TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(teams)
    @notifier.expects(:standings).with { |value| value.size == 3 }

    assert_equal :sent, @trigger.send!("standings")
  end

  test "countdown sends live rank and gap" do
    TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(teams)
    @notifier.expects(:countdown_started).with do |data|
      data[:rank] == 2 && data[:escape_team] == "APEX" && data[:gap] == 820
    end

    assert_equal :sent, @trigger.send!("countdown")
  end

  test "countdown reports first place instead of sending" do
    TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(teams(ours: 9999))
    @notifier.expects(:countdown_started).never

    assert_equal :first_place, @trigger.send!("countdown")
  end

  test "rejects unknown kinds" do
    assert_raises(ArgumentError) { @trigger.send!("push_ours") }
  end

  private

  def teams(ours: 1298)
    [
      TornApi::Torn::Elimination::Team.new(86, "APEX", 2026, 0, 2118, 50, 8600, 7500, false, nil),
      TornApi::Torn::Elimination::Team.new(80, "Conspiracy Theorists", 2027, 0, ours, 48, 7900, 7500, false, nil),
      TornApi::Torn::Elimination::Team.new(89, "Brain Surgeons", 2027, 0, 488, 17, 4900, 5600, false, nil)
    ]
  end
end
