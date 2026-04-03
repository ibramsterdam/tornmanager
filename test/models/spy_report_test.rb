require "test_helper"

class SpyReportTest < ActiveSupport::TestCase
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test", xanax_target: 2.5)
  end

  test "recalculates total on save" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 0
    )

    assert_equal 1000, report.total
  end

  test "recalculates total on update" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 1000
    )

    report.update!(strength: 500)
    assert_equal 1400, report.total
  end

  test "validates torn_id uniqueness per faction" do
    @faction.spy_reports.create!(torn_id: 111, strength: 1, defense: 1, speed: 1, dexterity: 1, total: 4)
    duplicate = @faction.spy_reports.new(torn_id: 111, strength: 1, defense: 1, speed: 1, dexterity: 1, total: 4)
    assert_not duplicate.valid?
  end

  test "allows same torn_id in different factions" do
    other = Faction.create!(torn_id: 88888, name: "Other", xanax_target: 2.5)
    @faction.spy_reports.create!(torn_id: 111, strength: 1, defense: 1, speed: 1, dexterity: 1, total: 4)
    report = other.spy_reports.new(torn_id: 111, strength: 1, defense: 1, speed: 1, dexterity: 1, total: 4)
    assert report.valid?
  end
end
