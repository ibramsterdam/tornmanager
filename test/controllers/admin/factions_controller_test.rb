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
end
