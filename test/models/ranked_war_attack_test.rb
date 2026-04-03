require "test_helper"

class RankedWarAttackTest < ActiveSupport::TestCase
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test", xanax_target: 2.5)
    @war = @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy",
      started_at: 1.week.ago, ended_at: 3.days.ago, target_score: 100,
      our_score: 100, their_score: 50, winner_faction_id: @faction.torn_id
    )
  end

  test "belongs to ranked_war" do
    attack = RankedWarAttack.new(ranked_war: @war)
    assert_equal @war, attack.ranked_war
  end

  test "validates required fields" do
    attack = RankedWarAttack.new
    assert_not attack.valid?
    assert_includes attack.errors[:ranked_war], "must exist"
    assert_includes attack.errors[:torn_attack_id], "can't be blank"
    assert_includes attack.errors[:attacker_id], "can't be blank"
    assert_includes attack.errors[:defender_id], "can't be blank"
    assert_includes attack.errors[:result], "can't be blank"
  end

  test "validates uniqueness of torn_attack_id per war" do
    create_attack(torn_attack_id: 123)
    duplicate = build_attack(torn_attack_id: 123)
    assert_not duplicate.valid?
  end

  test "allows same torn_attack_id in different wars" do
    other_war = @faction.ranked_wars.create!(
      torn_war_id: 1002, opponent_faction_id: 77777, opponent_faction_name: "Other",
      started_at: 2.weeks.ago, ended_at: 1.week.ago, target_score: 100,
      our_score: 50, their_score: 100, winner_faction_id: 77777
    )

    create_attack(torn_attack_id: 123)
    other = build_attack(torn_attack_id: 123, ranked_war: other_war)
    assert other.valid?
  end

  test "outgoing scope returns attacks by our faction" do
    outgoing = create_attack(attacker_faction_id: @faction.torn_id)
    create_attack(torn_attack_id: 2, attacker_faction_id: 88888, defender_faction_id: @faction.torn_id)

    assert_includes RankedWarAttack.outgoing(@faction.torn_id), outgoing
    assert_equal 1, RankedWarAttack.outgoing(@faction.torn_id).count
  end

  test "incoming scope returns attacks against our faction" do
    create_attack(attacker_faction_id: @faction.torn_id, defender_faction_id: 88888)
    incoming = create_attack(torn_attack_id: 2, attacker_faction_id: 88888, defender_faction_id: @faction.torn_id)

    assert_includes RankedWarAttack.incoming(@faction.torn_id), incoming
    assert_equal 1, RankedWarAttack.incoming(@faction.torn_id).count
  end

  test "used_warlord? returns true when warlord modifier > 1" do
    attack = build_attack(warlord: 1.25)
    assert attack.used_warlord?
  end

  test "used_warlord? returns false when warlord is 1" do
    attack = build_attack(warlord: 1)
    assert_not attack.used_warlord?
  end

  test "overseas? returns true when overseas modifier > 1" do
    attack = build_attack(overseas: 1.5)
    assert attack.overseas?
  end

  private

  def build_attack(attrs = {})
    RankedWarAttack.new({
      ranked_war: @war,
      torn_attack_id: 1,
      attacker_id: 111, attacker_name: "Attacker", attacker_faction_id: @faction.torn_id,
      defender_id: 222, defender_name: "Defender", defender_faction_id: 88888,
      started: 1.week.ago.to_i, ended: 1.week.ago.to_i + 10,
      result: "Attacked", respect_gain: 5.0,
      fair_fight: 3, war: 2, warlord: 1, overseas: 1
    }.merge(attrs))
  end

  def create_attack(attrs = {})
    build_attack(attrs).tap(&:save!)
  end
end
