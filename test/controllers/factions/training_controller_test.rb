require "test_helper"

class Factions::TrainingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", track_stats: true, xanax_target: 2.5)
    @bram = users(:bram)
    @bram.update!(faction: @faction)
    sign_in_as(@bram)
  end

  test "shows backfill banner when members are being backfilled" do
    bert = users(:bert)
    bert.update!(faction: @faction, backfill_ends_at: 1.hour.from_now)

    get faction_training_path(@faction)

    assert_response :success
    assert_select ".backfill-members-banner", /1 member/
    assert_select ".backfill-members-banner", /Bert/
  end

  test "does not show backfill banner when no members are backfilling" do
    get faction_training_path(@faction)

    assert_response :success
    assert_select ".backfill-members-banner", count: 0
  end

  test "shows multiple member names in backfill banner" do
    bert = users(:bert)
    kaneki = users(:kaneki)
    bert.update!(faction: @faction, backfill_ends_at: 1.hour.from_now)
    kaneki.update!(faction: @faction, backfill_ends_at: 30.minutes.from_now)

    get faction_training_path(@faction)

    assert_response :success
    assert_select ".backfill-members-banner", /2 new members/
  end
end
