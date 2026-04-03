require "test_helper"

class FetchWarAttacksJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(torn_id: 9055, name: "Test Faction", xanax_target: 2.5)
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY", access_type: "Limited Access", faction_access: true)

    @war = @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy",
      started_at: 1.week.ago, ended_at: 3.days.ago, target_score: 100,
      our_score: 100, their_score: 50, winner_faction_id: @faction.torn_id,
      our_attacks: 3, their_attacks: 2
    )
  end

  test "fetches and stores all ranked war attacks" do
    attacks_page = {
      "attacks" => [
        build_api_attack(id: 1, attacker_faction_id: 9055, is_ranked_war: true, result: "Attacked"),
        build_api_attack(id: 2, attacker_faction_id: 9055, is_ranked_war: true, result: "Attacked"),
        build_api_attack(id: 3, attacker_faction_id: 9055, is_ranked_war: true, result: "Attacked"),
        build_api_attack(id: 4, attacker_faction_id: 88888, defender_faction_id: 9055, is_ranked_war: true, result: "Attacked"),
        build_api_attack(id: 5, attacker_faction_id: 88888, defender_faction_id: 9055, is_ranked_war: true, result: "Attacked"),
        build_api_attack(id: 6, attacker_faction_id: 9055, is_ranked_war: false, result: "Attacked")
      ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    TornApi::Faction::Attacks.any_instance.stubs(:get).returns(attacks_page)

    assert_difference "RankedWarAttack.count", 5 do
      FetchWarAttacksJob.perform_now(@war.id)
    end
  end

  test "skips non-ranked-war attacks" do
    attacks_page = {
      "attacks" => [
        build_api_attack(id: 1, is_ranked_war: false),
        build_api_attack(id: 2, is_ranked_war: true, result: "Attacked")
      ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    TornApi::Faction::Attacks.any_instance.stubs(:get).returns(attacks_page)

    assert_difference "RankedWarAttack.count", 1 do
      FetchWarAttacksJob.perform_now(@war.id)
    end
  end

  test "skips duplicate attacks on re-run" do
    @war.ranked_war_attacks.create!(
      torn_attack_id: 1, attacker_id: 111, defender_id: 222,
      started: 1.week.ago.to_i, ended: 1.week.ago.to_i + 10, result: "Attacked"
    )

    attacks_page = {
      "attacks" => [
        build_api_attack(id: 1, is_ranked_war: true, result: "Attacked"),
        build_api_attack(id: 2, is_ranked_war: true, result: "Attacked")
      ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    TornApi::Faction::Attacks.any_instance.stubs(:get).returns(attacks_page)

    assert_difference "RankedWarAttack.count", 1 do
      FetchWarAttacksJob.perform_now(@war.id)
    end
  end

  test "logs integrity warning when outgoing count mismatch" do
    @war.update!(our_attacks: 10)

    attacks_page = {
      "attacks" => [
        build_api_attack(id: 1, attacker_faction_id: 9055, is_ranked_war: true, result: "Attacked")
      ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    TornApi::Faction::Attacks.any_instance.stubs(:get).returns(attacks_page)

    Rails.logger.expects(:warn).with(regexp_matches(/outgoing 1\/10/))

    FetchWarAttacksJob.perform_now(@war.id)
  end

  test "passes integrity check when outgoing count matches" do
    @war.update!(our_attacks: 1)

    attacks_page = {
      "attacks" => [
        build_api_attack(id: 1, attacker_faction_id: 9055, is_ranked_war: true, result: "Attacked")
      ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    TornApi::Faction::Attacks.any_instance.stubs(:get).returns(attacks_page)

    Rails.logger.expects(:warn).never
    Rails.logger.stubs(:info)

    FetchWarAttacksJob.perform_now(@war.id)
  end

  test "requires faction api key with faction access" do
    @faction.torn_api_key.update!(faction_access: false)

    assert_no_difference "RankedWarAttack.count" do
      FetchWarAttacksJob.perform_now(@war.id)
    end
  end

  test "skips if war not found" do
    assert_nothing_raised do
      FetchWarAttacksJob.perform_now(999999)
    end
  end

  private

  def build_api_attack(id:, attacker_faction_id: 9055, defender_faction_id: 88888, is_ranked_war: true, result: "Attacked")
    {
      "id" => id,
      "code" => "abc#{id}",
      "started" => 1.week.ago.to_i,
      "ended" => 1.week.ago.to_i + 10,
      "attacker" => {
        "id" => 111 + id,
        "name" => "Attacker#{id}",
        "level" => 50,
        "faction" => { "id" => attacker_faction_id, "name" => "Faction" }
      },
      "defender" => {
        "id" => 222 + id,
        "name" => "Defender#{id}",
        "level" => 30,
        "faction" => { "id" => defender_faction_id, "name" => "Enemy" }
      },
      "result" => result,
      "respect_gain" => 5.0,
      "respect_loss" => 1.0,
      "chain" => id,
      "is_interrupted" => false,
      "is_stealthed" => false,
      "is_raid" => false,
      "is_ranked_war" => is_ranked_war,
      "modifiers" => {
        "fair_fight" => 3, "war" => 2, "retaliation" => 1,
        "group" => 1, "overseas" => 1, "chain" => 1, "warlord" => 1
      },
      "finishing_hit_effects" => []
    }
  end
end
