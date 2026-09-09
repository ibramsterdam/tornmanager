require "test_helper"

class EliminationSnapshotTest < ActiveSupport::TestCase
  test "record_teams inserts one row per team" do
    teams = [
      TornApi::Torn::Elimination::Team.new(80, "Conspiracy Theorists", 2027, 3, 1298, 48, 7900, 7500, false, nil),
      TornApi::Torn::Elimination::Team.new(86, "APEX", 2026, 2, 2118, 50, 8600, 7500, false, nil)
    ]

    at = Time.current.change(usec: 0)
    assert_difference "EliminationSnapshot.count", 2 do
      EliminationSnapshot.record_teams(teams, at: at)
    end

    row = EliminationSnapshot.find_by(team_torn_id: 80)
    assert_equal "Conspiracy Theorists", row.name
    assert_equal 1298, row.tickets
    assert_equal 48, row.lives
    assert_equal at, row.captured_at
  end
end
