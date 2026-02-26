require "test_helper"

class Factions::LeadershipControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", track_stats: true, xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    FactionSetting.create!(faction: @faction, torn_api_key: "FACTION_KEY")

    @bram = users(:bram)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
    @faction.faction_whitelists.create!(user: @bram)
  end

  # -- Data Coverage --

  test "show displays data coverage card with percentage" do
    member = User.create!(torn_id: 222222, name: "Member", level: 30, faction: @faction, fallen: false)

    start_date = PersonalStatSnapshot.tracking_start_date
    (start_date..PersonalStatSnapshot.tracking_end_date).each do |date|
      PersonalStatSnapshot.create!(user: @bram, date: date, timestamp: date.to_time.to_i)
    end

    sign_in_as(@bram)
    get faction_leadership_path(@faction)

    assert_response :success
    assert_select ".dashboard-stat-label", text: "Data Coverage"
  end

  test "data coverage is 100% when all snapshots present" do
    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date

    (start_date..end_date).each do |date|
      PersonalStatSnapshot.create!(user: @bram, date: date, timestamp: date.to_time.to_i)
    end

    sign_in_as(@bram)
    get faction_leadership_path(@faction)

    assert_response :success
    assert_select ".dashboard-stat-value .stat-compliant", text: "100.0%"
  end

  test "data coverage is 0% when no snapshots present" do
    sign_in_as(@bram)
    get faction_leadership_path(@faction)

    assert_response :success
    assert_select ".dashboard-stat-value .stat-danger", text: "0.0%"
  end

  test "data coverage uses correct color class for partial coverage" do
    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date
    all_dates = (start_date..end_date).to_a

    count = (all_dates.size * 0.8).ceil
    all_dates.first(count).each do |date|
      PersonalStatSnapshot.create!(user: @bram, date: date, timestamp: date.to_time.to_i)
    end

    sign_in_as(@bram)
    get faction_leadership_path(@faction)

    assert_response :success
    assert_select ".dashboard-stat-value .stat-warning"
  end

  # -- Delete Faction Data --

  test "delete_faction_data deletes faction setting (API keys)" do
    sign_in_as(@bram)

    assert_difference "FactionSetting.count", -1 do
      delete delete_faction_data_faction_leadership_path(@faction)
    end

    assert_nil @faction.reload.faction_setting
  end

  test "delete_faction_data deletes spy reports for this faction only" do
    other_faction = Faction.create!(
      torn_id: 88888, name: "Other Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0
    )

    @faction.spy_reports.create!(torn_id: 111, total: 1000, strength: 100, defense: 100, speed: 100, dexterity: 100)
    @faction.spy_reports.create!(torn_id: 222, total: 2000, strength: 200, defense: 200, speed: 200, dexterity: 200)
    other_spy = other_faction.spy_reports.create!(torn_id: 333, total: 3000, strength: 300, defense: 300, speed: 300, dexterity: 300)

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_equal 0, @faction.spy_reports.count
    assert SpyReport.exists?(other_spy.id), "Other faction's spy reports should NOT be deleted"
  end

  test "delete_faction_data deletes personal stat snapshots for faction members" do
    member = User.create!(torn_id: 222222, name: "Member", level: 30, faction: @faction)
    PersonalStatSnapshot.create!(user: @bram, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)
    PersonalStatSnapshot.create!(user: member, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_equal 0, PersonalStatSnapshot.where(user_id: [ @bram.id, member.id ]).count
  end

  test "delete_faction_data does not delete personal stats of users in other factions" do
    other_faction = Faction.create!(
      torn_id: 88888, name: "Other Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0
    )
    other_user = User.create!(torn_id: 999999, name: "OtherUser", level: 40, faction: other_faction)
    other_snapshot = PersonalStatSnapshot.create!(user: other_user, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    PersonalStatSnapshot.create!(user: @bram, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert PersonalStatSnapshot.exists?(other_snapshot.id), "Other faction's snapshots should NOT be deleted"
  end

  test "delete_faction_data deletes ranked wars" do
    @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy",
      started_at: 1.week.ago, ended_at: 3.days.ago, target_score: 100,
      our_score: 100, their_score: 50, winner_faction_id: @faction.torn_id
    )

    sign_in_as(@bram)

    assert_difference "RankedWar.count", -1 do
      delete delete_faction_data_faction_leadership_path(@faction)
    end
  end

  test "delete_faction_data clears the whitelist" do
    bert = users(:bert)
    bert.update!(faction: @faction)
    @faction.faction_whitelists.create!(user: bert)

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_equal 0, @faction.faction_whitelists.count
  end

  test "delete_faction_data stops war polling" do
    @faction.update!(war_polling_active: true)

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_not @faction.reload.war_polling_active?
  end

  test "delete_faction_data clears backfill status" do
    @faction.update!(backfill_ends_at: 1.hour.from_now, backfill_target_date: Date.yesterday)

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_nil @faction.reload.backfill_ends_at
    assert_nil @faction.reload.backfill_target_date
  end

  test "delete_faction_data preserves user subscription time" do
    original_expiry = @bram.subscription_expires_at

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_equal original_expiry, @bram.reload.subscription_expires_at,
      "Subscription time should NOT be revoked"
  end

  test "delete_faction_data marks faction setup as incomplete" do
    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_not @faction.reload.setup_completed?
  end

  test "delete_faction_data disables stat tracking" do
    assert @faction.track_stats?, "Precondition: track_stats should be true"

    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_not @faction.reload.track_stats?, "track_stats should be false after deletion"
  end

  test "delete_faction_data redirects to faction dashboard with notice" do
    sign_in_as(@bram)
    delete delete_faction_data_faction_leadership_path(@faction)

    assert_redirected_to faction_path(@faction)
    assert_equal "All faction data has been deleted. Subscription time has been preserved.", flash[:notice]
  end

  test "delete_faction_data requires authentication" do
    delete delete_faction_data_faction_leadership_path(@faction)
    assert_redirected_to new_session_path
  end
end
