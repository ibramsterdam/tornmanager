require "test_helper"

class Factions::LeadershipControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    FactionSetting.create!(faction: @faction, torn_api_key: "FACTION_KEY")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now, leadership_access: true)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now, leadership_access: true)
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

    @faction.users.active.each do |user|
      (start_date..end_date).each do |date|
        PersonalStatSnapshot.create!(user: user, date: date, timestamp: date.to_time.to_i)
      end
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

    # Create 80% coverage for ALL active members to get into warning range (70-90%)
    count = (all_dates.size * 0.8).ceil
    @faction.users.active.each do |user|
      all_dates.first(count).each do |date|
        PersonalStatSnapshot.create!(user: user, date: date, timestamp: date.to_time.to_i)
      end
    end

    sign_in_as(@bram)
    get faction_leadership_path(@faction)

    assert_response :success
    assert_select ".dashboard-stat-value .stat-warning"
  end

  # -- Setup --

  test "setup renders the setup page" do
    @faction.update!(setup_completed: false)
    @faction.faction_setting.destroy!

    sign_in_as(@bram)
    get faction_leadership_setup_path(@faction)

    assert_response :success
  end

  test "setup is accessible without leadership access or setup_completed" do
    @faction.update!(setup_completed: false)
    @faction.faction_setting.destroy!
    @bram.update!(leadership_access: false)

    sign_in_as(@bram)
    get faction_leadership_setup_path(@faction)

    assert_response :success
  end

  # -- Complete Setup --

  test "complete_setup saves torn api key with valid limited access key" do
    @faction.faction_setting.destroy!
    stub_valid_key_info(@bram, @faction.torn_id)

    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "NEW_LIMITED_KEY" }
    }

    assert_redirected_to faction_leadership_path(@faction)
    assert_match /configured successfully/, flash[:notice]
    assert_equal "NEW_LIMITED_KEY", @faction.reload.faction_setting.torn_api_key
    assert_equal "Limited Access", @faction.faction_setting.torn_api_access_type
  end

  test "complete_setup saves both torn and tornstats keys" do
    @faction.faction_setting.destroy!
    stub_valid_key_info(@bram, @faction.torn_id)

    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "NEW_LIMITED_KEY", tornstats_api_key: "TORNSTATS_KEY" }
    }

    assert_redirected_to faction_leadership_path(@faction)
    setting = @faction.reload.faction_setting
    assert_equal "NEW_LIMITED_KEY", setting.torn_api_key
    assert_equal "TORNSTATS_KEY", setting.tornstats_api_key
  end

  test "complete_setup rejects missing torn api key" do
    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "" }
    }

    assert_redirected_to faction_leadership_setup_path(@faction)
    assert_match /required/, flash[:alert]
  end

  test "complete_setup rejects non-limited access key" do
    stub_key_info(@bram, @faction.torn_id, access_type: "Public Only")

    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "PUBLIC_KEY" }
    }

    assert_redirected_to faction_leadership_setup_path(@faction)
    assert_match /Limited Access/, flash[:alert]
  end

  test "complete_setup rejects key belonging to different user" do
    stub_key_info_for_different_user(@faction.torn_id)

    sign_in_as(@bert)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "WRONG_USER_KEY" }
    }

    assert_redirected_to faction_leadership_setup_path(@faction)
    assert_match /does not belong to you/, flash[:alert]
  end

  test "complete_setup handles invalid key error" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "BAD_KEY" }
    }

    assert_redirected_to faction_leadership_setup_path(@faction)
    assert_match /Invalid/, flash[:alert]
  end

  test "complete_setup handles api error" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::ApiError, "timeout")

    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "TIMEOUT_KEY" }
    }

    assert_redirected_to faction_leadership_setup_path(@faction)
    assert_match /Could not validate/, flash[:alert]
  end

  # -- War Data --

  test "war_data returns cached war data as json" do
    war_data = { "status" => "active", "score" => 50 }
    Rails.cache.stubs(:read).with(@faction.war_cache_key).returns(war_data)

    sign_in_as(@bram)
    get war_data_faction_leadership_path(@faction), as: :json

    assert_response :success
    parsed = JSON.parse(response.body)
    assert_equal "active", parsed["status"]
    assert_equal 50, parsed["score"]
  end

  test "war_data returns no_content when no cached data" do
    sign_in_as(@bram)
    get war_data_faction_leadership_path(@faction), as: :json

    assert_response :no_content
  end

  # -- Update Keys --

  test "update_keys updates torn api key with valid key" do
    stub_valid_key_info(@bram, @faction.torn_id)

    sign_in_as(@bram)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { torn_api_key: "UPDATED_KEY" }
    }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /saved successfully/, flash[:notice]
    assert_equal "UPDATED_KEY", @faction.reload.faction_setting.torn_api_key
  end

  test "update_keys updates only tornstats key when no torn key provided" do
    sign_in_as(@bram)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { tornstats_api_key: "NEW_TORNSTATS_KEY" }
    }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /saved successfully/, flash[:notice]
    assert_equal "NEW_TORNSTATS_KEY", @faction.reload.faction_setting.tornstats_api_key
    assert_equal "FACTION_KEY", @faction.faction_setting.torn_api_key, "Torn key should be unchanged"
  end

  test "update_keys reports no changes when both keys blank" do
    sign_in_as(@bram)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { torn_api_key: "", tornstats_api_key: "" }
    }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /No changes/, flash[:notice]
  end

  test "update_keys rejects non-limited access torn key" do
    stub_key_info(@bram, @faction.torn_id, access_type: "Public Only")

    sign_in_as(@bram)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { torn_api_key: "PUBLIC_KEY" }
    }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /Limited Access/, flash[:alert]
  end

  test "update_keys rejects invalid torn key" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    sign_in_as(@bram)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { torn_api_key: "BAD_KEY" }
    }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /Invalid/, flash[:alert]
  end

  # -- Delete Torn Key --

  test "delete_torn_key clears the torn api key" do
    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "torn")

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /deleted/, flash[:notice]

    setting = @faction.reload.faction_setting
    assert_nil setting.torn_api_key
    assert_nil setting.torn_api_access_type
  end

  test "delete_torn_key redirects to setup when no setting exists" do
    @faction.faction_setting.destroy!

    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "torn")

    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  # -- Delete TornStats Key --

  test "delete_tornstats_key clears the tornstats api key" do
    @faction.faction_setting.update!(tornstats_api_key: "SOME_KEY")

    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "tornstats")

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /deleted/, flash[:notice]
    assert_nil @faction.reload.faction_setting.tornstats_api_key
  end

  test "delete_tornstats_key redirects to setup when no setting exists" do
    @faction.faction_setting.destroy!

    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "tornstats")

    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  # -- Grant Leadership Access --

  test "grant_leadership_access grants access to a faction member" do
    member = User.create!(torn_id: 555555, name: "NewMember", level: 30, faction: @faction)

    sign_in_as(@bram)
    post faction_leadership_leadership_access_path(@faction), params: { user_id: member.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert member.reload.leadership_access?
    assert_match /granted access/, flash[:notice]
  end

  test "grant_leadership_access handles user who already has access" do
    sign_in_as(@bram)
    post faction_leadership_leadership_access_path(@faction), params: { user_id: @bert.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /already has access/, flash[:notice]
  end

  test "grant_leadership_access handles user not found" do
    sign_in_as(@bram)
    post faction_leadership_leadership_access_path(@faction), params: { user_id: 0 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /not found/, flash[:alert]
  end

  # -- Revoke Leadership Access --

  test "revoke_leadership_access removes access from a user" do
    sign_in_as(@bram)
    delete faction_leadership_leadership_access_path(@faction), params: { user_id: @bert.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_not @bert.reload.leadership_access?
    assert_match /removed/, flash[:notice]
  end

  test "revoke_leadership_access handles user without access" do
    member = User.create!(torn_id: 555555, name: "NoAccess", level: 30, faction: @faction)

    sign_in_as(@bram)
    delete faction_leadership_leadership_access_path(@faction), params: { user_id: member.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /not found in leadership/, flash[:alert]
  end

  # -- Share Subscription --

  test "share_subscription distributes weeks evenly across members" do
    @bram.update!(subscription_expires_at: 52.weeks.from_now)
    member = User.create!(torn_id: 555555, name: "Member", level: 30, faction: @faction, subscription_expires_at: 1.week.from_now)

    # 3 active members: bram, bert, member (all non-fallen)
    active_count = @faction.users.active.count

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { total_weeks: active_count }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /Shared #{active_count} weeks/, flash[:notice]
  end

  test "share_subscription rejects zero weeks" do
    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { total_weeks: 0 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /valid number/, flash[:alert]
  end

  test "share_subscription rejects negative weeks" do
    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { total_weeks: -5 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /valid number/, flash[:alert]
  end

  test "share_subscription rejects uneven split" do
    # 2 active members (bram + bert), but asking for 3 weeks — doesn't divide evenly
    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { total_weeks: 3 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /cannot be split evenly/, flash[:alert]
  end

  test "share_subscription rejects when user has insufficient weeks" do
    @bram.update!(subscription_expires_at: 1.week.from_now)
    active_count = @faction.users.active.count

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { total_weeks: active_count * 10 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /weeks remaining/, flash[:alert]
  end

  test "share_subscription creates faction subscription grant record" do
    @bram.update!(subscription_expires_at: 52.weeks.from_now)
    active_count = @faction.users.active.count

    sign_in_as(@bram)

    assert_difference "FactionSubscriptionGrant.count", 1 do
      post faction_leadership_subscriptions_path(@faction), params: { total_weeks: active_count }
    end

    grant = FactionSubscriptionGrant.last
    assert_equal @faction.torn_id, grant.torn_faction_id
    assert_equal @bram, grant.granted_by
    assert_equal active_count, grant.weeks_granted
  end

  test "share_subscription creates individual subscription grants for each member" do
    @bram.update!(subscription_expires_at: 52.weeks.from_now)
    active_count = @faction.users.active.count

    sign_in_as(@bram)

    assert_difference "SubscriptionGrant.count", active_count do
      post faction_leadership_subscriptions_path(@faction), params: { total_weeks: active_count }
    end
  end

  test "share_subscription deducts weeks from granting user" do
    @bram.update!(subscription_expires_at: 52.weeks.from_now)
    original_weeks = @bram.subscription_weeks_remaining
    active_count = @faction.users.active.count

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { total_weeks: active_count }

    remaining = @bram.reload.subscription_weeks_remaining
    assert remaining < original_weeks, "Subscription should be deducted"
  end

  # -- Import Spies --

  test "import_spies imports spy reports from tornstats" do
    @faction.faction_setting.update!(tornstats_api_key: "TORNSTATS_KEY")

    spy_data = [
      TornStatsApi::SpyFaction::SpyData.new(
        torn_id: 111, name: "Target1", level: 50,
        strength: 1000, defense: 2000, speed: 3000, dexterity: 4000,
        total: 10000, spied_at: 1.day.ago
      ),
      TornStatsApi::SpyFaction::SpyData.new(
        torn_id: 222, name: "Target2", level: 60,
        strength: 5000, defense: 6000, speed: 7000, dexterity: 8000,
        total: 26000, spied_at: 2.days.ago
      )
    ]
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).returns(spy_data)

    sign_in_as(@bram)

    assert_difference "@faction.spy_reports.count", 2 do
      post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }
    end

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /imported 2/, flash[:notice]
  end

  test "import_spies rejects blank faction id" do
    @faction.faction_setting.update!(tornstats_api_key: "TORNSTATS_KEY")

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /enter a faction ID/, flash[:alert]
  end

  test "import_spies rejects when tornstats key not configured" do
    @faction.faction_setting.update!(tornstats_api_key: nil)

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /TornStats API key must be configured/, flash[:alert]
  end

  test "import_spies enforces rate limiting" do
    @faction.faction_setting.update!(tornstats_api_key: "TORNSTATS_KEY")

    # Stub cache to simulate a recent import (test uses :null_store)
    cache_key = "faction:#{@faction.id}:spy_import:last_run"
    Rails.cache.stubs(:exist?).with(cache_key).returns(true)
    Rails.cache.stubs(:read).with(cache_key).returns(Time.current)

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /recently/, flash[:alert]
  end

  test "import_spies handles not found error" do
    @faction.faction_setting.update!(tornstats_api_key: "TORNSTATS_KEY")
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).raises(TornStatsApi::NotFoundError, "No data")

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /No spy data found/, flash[:alert]
  end

  test "import_spies handles invalid key error" do
    @faction.faction_setting.update!(tornstats_api_key: "BAD_KEY")
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).raises(TornStatsApi::InvalidKeyError, "Bad key")

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /Invalid TornStats API key/, flash[:alert]
  end

  test "import_spies upserts existing spy reports" do
    @faction.faction_setting.update!(tornstats_api_key: "TORNSTATS_KEY")
    @faction.spy_reports.create!(torn_id: 111, total: 5000, strength: 100, defense: 100, speed: 100, dexterity: 100)

    spy_data = [
      TornStatsApi::SpyFaction::SpyData.new(
        torn_id: 111, name: "Target1", level: 50,
        strength: 9000, defense: 9000, speed: 9000, dexterity: 9000,
        total: 36000, spied_at: 1.day.ago
      )
    ]
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).returns(spy_data)

    sign_in_as(@bram)

    assert_no_difference "@faction.spy_reports.count" do
      post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }
    end

    assert_equal 36000, @faction.spy_reports.find_by(torn_id: 111).total
  end

  # -- Delete Faction Data --

  test "delete_faction_data deletes faction setting (API keys)" do
    sign_in_as(@bram)

    assert_difference "FactionSetting.count", -1 do
      delete faction_leadership_faction_data_path(@faction)
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
    delete faction_leadership_faction_data_path(@faction)

    assert_equal 0, @faction.spy_reports.count
    assert SpyReport.exists?(other_spy.id), "Other faction's spy reports should NOT be deleted"
  end

  test "delete_faction_data deletes personal stat snapshots for faction members" do
    member = User.create!(torn_id: 222222, name: "Member", level: 30, faction: @faction)
    PersonalStatSnapshot.create!(user: @bram, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)
    PersonalStatSnapshot.create!(user: member, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

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
    delete faction_leadership_faction_data_path(@faction)

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
      delete faction_leadership_faction_data_path(@faction)
    end
  end

  test "delete_faction_data revokes leadership access" do
    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert_equal 0, @faction.leadership.count
  end

  test "delete_faction_data stops war polling" do
    @faction.update!(war_polling_active: true)

    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert_not @faction.reload.war_polling_active?
  end

  test "delete_faction_data clears backfill status" do
    @faction.update!(backfill_ends_at: 1.hour.from_now, backfill_target_date: Date.yesterday)

    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert_nil @faction.reload.backfill_ends_at
    assert_nil @faction.reload.backfill_target_date
  end

  test "delete_faction_data preserves user subscription time" do
    original_expiry = @bram.subscription_expires_at

    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert_equal original_expiry, @bram.reload.subscription_expires_at,
      "Subscription time should NOT be revoked"
  end

  test "delete_faction_data marks faction setup as incomplete" do
    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert_not @faction.reload.setup_completed?
  end

  test "delete_faction_data redirects to faction dashboard with notice" do
    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert_redirected_to faction_path(@faction)
    assert_equal "All faction data has been deleted. Subscription time has been preserved.", flash[:notice]
  end

  test "delete_faction_data requires authentication" do
    delete faction_leadership_faction_data_path(@faction)
    assert_redirected_to new_session_path
  end

  # -- Access control --

  test "member without leadership access cannot access show" do
    kaneki = users(:kaneki)
    kaneki.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    sign_in_as(kaneki)
    get faction_leadership_path(@faction)

    assert_redirected_to faction_path(@faction)
  end

  test "member without leadership access cannot access mutating actions" do
    kaneki = users(:kaneki)
    kaneki.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    sign_in_as(kaneki)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { torn_api_key: "KEY" }
    }

    assert_redirected_to faction_path(@faction)
  end

  private

  def stub_valid_key_info(user, faction_torn_id)
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: user.torn_id, faction_id: faction_torn_id, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
  end

  def stub_key_info(user, faction_torn_id, access_type:)
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: access_type, faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: user.torn_id, faction_id: faction_torn_id, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
  end

  def stub_key_info_for_different_user(faction_torn_id)
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: faction_torn_id, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
  end
end
