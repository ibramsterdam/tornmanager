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

  test "excludes user whose faction has no api keys at all" do
    faction = factions(:without_api_key)
    faction.api_keys.destroy_all
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
