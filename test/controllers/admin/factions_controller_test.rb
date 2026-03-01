require "test_helper"

class Admin::FactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    @admin = users(:bram) # torn_id 2728237 = admin
    sign_in_as(@admin)
  end

  test "toggle_public_wars enables public access" do
    assert_not @faction.public_wars?

    patch toggle_public_wars_admin_faction_path(@faction), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["public_wars"]

    @faction.reload
    assert @faction.public_wars?
  end

  test "toggle_public_wars disables public access" do
    @faction.update!(public_wars: true)

    patch toggle_public_wars_admin_faction_path(@faction), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not json["public_wars"]

    @faction.reload
    assert_not @faction.public_wars?
  end

  test "destroy resets faction data and requires re-setup" do
    setting = FactionSetting.create!(faction: @faction, torn_api_key: "abc123")
    @faction.update!(setup_completed: true)
    @faction.ranked_wars.create!(
      torn_war_id: 1, opponent_faction_id: 12345, opponent_faction_name: "Enemy",
      started_at: 1.day.ago, target_score: 100, our_score: 50, their_score: 40
    )

    assert_no_difference "Faction.count" do
      delete admin_faction_path(@faction)
    end

    assert_redirected_to admin_factions_path
    @faction.reload
    assert_not @faction.setup_completed?
    assert_not FactionSetting.exists?(setting.id)
    assert_equal 0, @faction.ranked_wars.count
  end
end
