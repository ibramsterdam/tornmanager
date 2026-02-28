require "test_helper"

class Factions::RankedWarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    @war = @faction.ranked_wars.create!(
      torn_war_id: 1001,
      opponent_faction_id: 88888,
      opponent_faction_name: "Enemy Faction",
      started_at: Date.new(2026, 1, 15).to_time,
      ended_at: Date.new(2026, 1, 16).to_time,
      target_score: 100,
      our_score: 100,
      their_score: 50,
      winner_faction_id: @faction.torn_id,
      our_attacks: 500,
      their_attacks: 300,
      respect_gained: 5000,
      points_gained: 10,
      rank_before: "Diamond I",
      rank_after: "Diamond II",
      our_members: [
        { "id" => @bram.torn_id, "name" => "Bram", "attacks" => 100, "score" => 50.5 },
        { "id" => @bert.torn_id, "name" => "Bert", "attacks" => 80, "score" => 30.2 }
      ],
      their_members: [
        { "id" => 9999999, "name" => "Enemy1", "attacks" => 150, "score" => 25.0 }
      ]
    )
  end

  test "show renders war detail page for faction member" do
    sign_in_as(@bram)
    get faction_ranked_war_path(@faction, @war)
    assert_response :success
    assert_select ".war-overview"
  end

  test "show displays opponent name and scores" do
    sign_in_as(@bram)
    get faction_ranked_war_path(@faction, @war)
    assert_response :success
    assert_select ".faction-name", @faction.name
    assert_select ".faction-name", "Enemy Faction"
  end

  test "show displays war stats comparison" do
    sign_in_as(@bram)
    get faction_ranked_war_path(@faction, @war)
    assert_response :success
    assert_select ".war-stats-comparison"
  end

  test "show displays our members table" do
    sign_in_as(@bram)
    get faction_ranked_war_path(@faction, @war)
    assert_response :success
    assert_select ".war-members-grid"
    assert_select "td", /Bram/
    assert_select "td", /Bert/
  end

  test "show redirects unauthenticated user" do
    get faction_ranked_war_path(@faction, @war)
    assert_redirected_to new_session_path
  end

  test "show redirects non-member to root" do
    other_faction = Faction.create!(
      torn_id: 11111, name: "Other", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0
    )
    @bert.update!(faction: other_faction)
    sign_in_as(@bert)

    get faction_ranked_war_path(@faction, @war)
    assert_redirected_to root_path
  end

  test "show returns 404 for war belonging to different faction" do
    other_faction = Faction.create!(
      torn_id: 11111, name: "Other", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @bert.update!(faction: other_faction, subscription_expires_at: 1.month.from_now)
    sign_in_as(@bert)

    get faction_ranked_war_path(other_faction, @war)
    assert_redirected_to root_path
  end
end
