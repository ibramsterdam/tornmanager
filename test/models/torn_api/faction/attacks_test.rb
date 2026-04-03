require "test_helper"

class TornApi::Faction::AttacksTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_key"
  end

  test "fetches attacks with default params" do
    api_response = {
      "attacks" => [
        build_attack_response(id: 1, attacker_name: "Bram", defender_name: "Enemy1"),
        build_attack_response(id: 2, attacker_name: "Ally", defender_name: "Enemy2")
      ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key)
    service.expects(:get).with("v2/faction/attacks", { limit: 100, sort: "DESC" }).returns(api_response)

    result = service.fetch
    assert_equal 2, result.attacks.size
    assert_nil result.prev_url
  end

  test "fetches attacks with time range" do
    api_response = {
      "attacks" => [ build_attack_response(id: 1) ],
      "_metadata" => { "links" => { "prev" => "https://api.torn.com/v2/faction/attacks?to=123", "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key, from: 1000, to: 2000)
    service.expects(:get).with("v2/faction/attacks", { limit: 100, sort: "DESC", from: 1000, to: 2000 }).returns(api_response)

    result = service.fetch
    assert_equal 1, result.attacks.size
    assert_equal "https://api.torn.com/v2/faction/attacks?to=123", result.prev_url
  end

  test "fetches outgoing attacks only" do
    api_response = {
      "attacks" => [],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key, filters: "outgoing")
    service.expects(:get).with("v2/faction/attacks", { limit: 100, sort: "DESC", filters: "outgoing" }).returns(api_response)

    result = service.fetch
    assert_empty result.attacks
  end

  test "parses attack data into structs" do
    api_response = {
      "attacks" => [ build_attack_response(
        id: 459887212,
        attacker_id: 2728237, attacker_name: "Bram", attacker_level: 73,
        attacker_faction_id: 9055, attacker_faction_name: "Natural Selection IV",
        defender_id: 1600780, defender_name: "Illness", defender_level: 24,
        defender_faction_id: nil, defender_faction_name: nil,
        result: "Attacked", respect_gain: 5.77, chain: 480,
        is_ranked_war: true, is_stealthed: false,
        fair_fight: 2.45, war: 2, overseas: 1, warlord: 1.25,
        finishing_hit_effects: [ { "name" => "warlord", "value" => 25 } ]
      ) ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key)
    service.expects(:get).returns(api_response)

    attack = service.fetch.attacks.first

    assert_equal 459887212, attack.id
    assert_equal 2728237, attack.attacker_id
    assert_equal "Bram", attack.attacker_name
    assert_equal 9055, attack.attacker_faction_id
    assert_equal 1600780, attack.defender_id
    assert_equal "Illness", attack.defender_name
    assert_equal "Attacked", attack.result
    assert_in_delta 5.77, attack.respect_gain
    assert_equal 480, attack.chain
    assert attack.is_ranked_war
    assert_not attack.is_stealthed
    assert_in_delta 2.45, attack.fair_fight
    assert_in_delta 2, attack.war
    assert_in_delta 1, attack.overseas
    assert_in_delta 1.25, attack.warlord
    assert_equal [ { "name" => "warlord", "value" => 25 } ], attack.finishing_hit_effects
  end

  test "handles empty attacks array" do
    api_response = {
      "attacks" => [],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key)
    service.expects(:get).returns(api_response)

    result = service.fetch
    assert_empty result.attacks
  end

  test "fetch_all paginates through all pages" do
    page1 = {
      "attacks" => [ build_attack_response(id: 3), build_attack_response(id: 2) ],
      "_metadata" => { "links" => { "prev" => "https://api.torn.com/v2/faction/attacks?to=1000&limit=100&sort=desc", "next" => nil } }
    }
    page2 = {
      "attacks" => [ build_attack_response(id: 1) ],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key, from: 500)
    service.expects(:get).with("v2/faction/attacks", { limit: 100, sort: "DESC", from: 500 }).returns(page1)
    service.expects(:get).with("v2/faction/attacks", { limit: 100, sort: "DESC", from: 500, to: 1000 }).returns(page2)

    attacks = service.fetch_all
    assert_equal 3, attacks.size
    assert_equal [3, 2, 1], attacks.map(&:id)
  end

  test "fetch_all stops at max pages to prevent infinite loops" do
    response = {
      "attacks" => [ build_attack_response(id: 1) ],
      "_metadata" => { "links" => { "prev" => "https://api.torn.com/v2/faction/attacks?to=1000", "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key)
    service.stubs(:get).returns(response)

    attacks = service.fetch_all(max_pages: 3)
    assert_equal 3, attacks.size
  end

  test "fetch_all returns empty array when no attacks" do
    api_response = {
      "attacks" => [],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key)
    service.expects(:get).returns(api_response)

    assert_empty service.fetch_all
  end

  test "custom limit" do
    api_response = {
      "attacks" => [],
      "_metadata" => { "links" => { "prev" => nil, "next" => nil } }
    }

    service = TornApi::Faction::Attacks.new(@api_key, limit: 50)
    service.expects(:get).with("v2/faction/attacks", { limit: 50, sort: "DESC" }).returns(api_response)

    service.fetch
  end

  private

  def build_attack_response(
    id: 1, started: 1774472479, ended: 1774472489,
    attacker_id: 123, attacker_name: "Attacker", attacker_level: 50,
    attacker_faction_id: 9055, attacker_faction_name: "Test Faction",
    defender_id: 456, defender_name: "Defender", defender_level: 30,
    defender_faction_id: 8888, defender_faction_name: "Enemy Faction",
    result: "Attacked", respect_gain: 3.36, respect_loss: 0.84, chain: 1,
    is_ranked_war: false, is_stealthed: false, is_interrupted: false, is_raid: false,
    fair_fight: 3, war: 1, retaliation: 1, group: 1, overseas: 1, warlord: 1,
    finishing_hit_effects: []
  )
    {
      "id" => id,
      "code" => "abc123",
      "started" => started,
      "ended" => ended,
      "attacker" => {
        "id" => attacker_id,
        "name" => attacker_name,
        "level" => attacker_level,
        "faction" => attacker_faction_id ? { "id" => attacker_faction_id, "name" => attacker_faction_name } : nil
      },
      "defender" => {
        "id" => defender_id,
        "name" => defender_name,
        "level" => defender_level,
        "faction" => defender_faction_id ? { "id" => defender_faction_id, "name" => defender_faction_name } : nil
      },
      "result" => result,
      "respect_gain" => respect_gain,
      "respect_loss" => respect_loss,
      "chain" => chain,
      "is_interrupted" => is_interrupted,
      "is_stealthed" => is_stealthed,
      "is_raid" => is_raid,
      "is_ranked_war" => is_ranked_war,
      "modifiers" => {
        "fair_fight" => fair_fight,
        "war" => war,
        "retaliation" => retaliation,
        "group" => group,
        "overseas" => overseas,
        "chain" => 1,
        "warlord" => warlord
      },
      "finishing_hit_effects" => finishing_hit_effects
    }
  end
end
