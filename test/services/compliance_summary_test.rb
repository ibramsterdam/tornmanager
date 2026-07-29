require "test_helper"

class ComplianceSummaryTest < ActiveSupport::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999,
      name: "Test Faction",
      xanax_target: 2.5,
      energy_refill_target: 1.0,
      nerve_refill_target: 1.0,
      setup_completed: true
    )
    @user = users(:bert)
    @user.update!(faction: @faction, fallen: false)

    @start_date = Date.new(2026, 1, 1)
    @end_date = Date.new(2026, 1, 8)

    create_snapshots(@user, @start_date - 1.day, @end_date)
  end

  test "computes member rows from snapshots" do
    with_memory_cache do
      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)

      assert_equal 1, summary.member_rows.size
      assert_equal @user.torn_id, summary.member_rows.first[:torn_id]
    end
  end

  test "returns cached results on second call with same parameters" do
    with_memory_cache do
      summary1 = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      assert_equal 1, summary1.member_rows.size

      PersonalStatSnapshot.where(user_id: @user.id).delete_all

      summary2 = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      assert_equal 1, summary2.member_rows.size, "Should return cached results even after snapshots are deleted"
    end
  end

  test "cache is keyed by date range" do
    with_memory_cache do
      summary1 = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      assert_equal 1, summary1.member_rows.size

      different_start = @start_date + 1.day
      summary2 = ComplianceSummary.new(@faction, start_date: different_start, end_date: @end_date)
      assert_equal 1, summary2.member_rows.size, "Different date range should still compute (not share cache)"
    end
  end

  test "cache busts when faction targets change" do
    with_memory_cache do
      original_score = nil

      travel_to Time.current do
        @faction.update!(xanax_target: 10.0)

        summary1 = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
        original_score = summary1.member_rows.first[:compliance_score]
        assert original_score < 100, "Score should be below 100 when target is high"
      end

      travel_to 2.seconds.from_now do
        @faction.update!(xanax_target: 0.1)

        summary2 = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
        new_score = summary2.member_rows.first[:compliance_score]

        assert new_score > original_score, "Lowering target should bust cache and increase score"
      end
    end
  end

  test "cache is scoped to faction" do
    with_memory_cache do
      other_faction = Faction.create!(
        torn_id: 88888, name: "Other Faction",
        xanax_target: 2.5, energy_refill_target: 1.0, nerve_refill_target: 1.0
      )
      other_user = users(:kaneki)
      other_user.update!(faction: other_faction, fallen: false)
      create_snapshots(other_user, @start_date - 1.day, @end_date)

      summary1 = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      summary2 = ComplianceSummary.new(other_faction, start_date: @start_date, end_date: @end_date)

      assert_equal @user.torn_id, summary1.member_rows.first[:torn_id]
      assert_equal other_user.torn_id, summary2.member_rows.first[:torn_id]
    end
  end

  test "computes compliance counts correctly" do
    with_memory_cache do
      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)

      total = summary.compliant_count + summary.warning_count + summary.non_compliant_count
      assert_equal summary.member_rows.size, total
    end
  end

  test "worst_performers puts the lowest compliance score first" do
    with_memory_cache do
      slacker = users(:kaneki)
      slacker.update!(faction: @faction, fallen: false)
      create_snapshots(slacker, @start_date - 1.day, @end_date, xanax_step: 0)

      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      worst = summary.worst_performers(1)

      assert_equal 1, worst.size
      assert_equal slacker.torn_id, worst.first[:torn_id],
        "the member with zero xanax gained must rank worst"
    end
  end

  test "loads snapshots for the whole roster in a single query" do
    with_memory_cache do
      other_user = users(:kaneki)
      other_user.update!(faction: @faction, fallen: false)
      create_snapshots(other_user, @start_date - 1.day, @end_date)

      snapshot_queries = 0
      counter = ->(_name, _start, _finish, _id, payload) do
        sql = payload[:sql].to_s
        snapshot_queries += 1 if sql.start_with?("SELECT") && sql.include?("personal_stat_snapshots")
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
        assert_equal 2, summary.member_rows.size
      end

      assert_equal 1, snapshot_queries
    end
  end

  test "ssl users pass xanax compliance regardless of the target" do
    with_memory_cache do
      @user.update!(ssl_user: true)
      @faction.update!(xanax_target: 100.0)

      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      row = summary.member_rows.first

      assert row[:ssl_user]
      assert_equal :green, row[:xanax_compliance]
    end
  end

  test "a member with a single snapshot is skipped rather than scored on zero days" do
    with_memory_cache do
      one_day_user = users(:kaneki)
      one_day_user.update!(faction: @faction, fallen: false)
      create_snapshots(one_day_user, @start_date, @start_date)

      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)

      assert_not_includes summary.member_rows.map { |r| r[:torn_id] }, one_day_user.torn_id
    end
  end

  test "total_days is calculated from date range" do
    with_memory_cache do
      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)
      expected_days = (@end_date - @start_date).to_i + 1
      assert_equal expected_days, summary.total_days
    end
  end

  test "skips users with no snapshot data" do
    with_memory_cache do
      no_data_user = users(:kaneki)
      no_data_user.update!(faction: @faction, fallen: false)

      summary = ComplianceSummary.new(@faction, start_date: @start_date, end_date: @end_date)

      torn_ids = summary.member_rows.map { |r| r[:torn_id] }
      assert_includes torn_ids, @user.torn_id
      assert_not_includes torn_ids, no_data_user.torn_id
    end
  end

  private

  def create_snapshots(user, from_date, to_date, xanax_base: 0, xanax_step: 3)
    (from_date..to_date).each_with_index do |date, i|
      PersonalStatSnapshot.create!(
        user: user,
        date: date,
        drugs_xanax: xanax_base + (i * xanax_step),
        other_refills_energy: i * 1,
        other_refills_nerve: i * 1,
        missions_contracts_total: i * 2,
        crimes_offenses_total: i * 5,
        other_activity_time: i * 60,
        networth_total: 1_000_000 + (i * 10_000)
      )
    end
  end

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
