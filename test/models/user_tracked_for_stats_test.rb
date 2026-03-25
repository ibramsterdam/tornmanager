require "test_helper"

class UserTrackedForStatsTest < ActiveSupport::TestCase
  test "includes user whose faction has an api key" do
    user = users(:user_with_keyed_faction)
    assert_includes User.tracked_for_stats, user
  end

  test "excludes user whose faction has no api key" do
    user = users(:user_with_unkeyed_faction)
    assert_not_includes User.tracked_for_stats, user
  end

  test "excludes user whose faction has no faction_setting at all" do
    # Remove the faction_setting for the unkeyed faction to simulate no setting record
    faction = factions(:without_api_key)
    faction.faction_setting.destroy!
    user = users(:user_with_unkeyed_faction)
    assert_not_includes User.tracked_for_stats, user
  end

  test "includes hof_stats_user without faction" do
    user = users(:user_hof_no_faction)
    assert_includes User.tracked_for_stats, user
  end

  test "excludes fallen users even with keyed faction" do
    user = users(:user_with_keyed_faction)
    user.update!(fallen: true)
    assert_not_includes User.tracked_for_stats, user
  end
end
