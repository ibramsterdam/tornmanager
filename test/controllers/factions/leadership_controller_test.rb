require "test_helper"

class Factions::LeadershipControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    FactionSetting.create!(faction: @faction)
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, leadership_access: true)
    @bert.update!(faction: @faction, leadership_access: true)
    grant_subscription(@faction, expires_at: 1.month.from_now)
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
    assert_equal "NEW_LIMITED_KEY", @faction.reload.torn_api_key.key
    assert_equal "Limited Access", @faction.torn_api_key.access_type
    assert @faction.torn_api_key.faction_access?, "faction_access should be stored from key info"
  end

  test "complete_setup saves both torn and tornstats keys" do
    @faction.faction_setting.destroy!
    stub_valid_key_info(@bram, @faction.torn_id)

    sign_in_as(@bram)
    patch faction_leadership_setup_path(@faction), params: {
      faction_setting: { torn_api_key: "NEW_LIMITED_KEY", tornstats_api_key: "TORNSTATS_KEY" }
    }

    assert_redirected_to faction_leadership_path(@faction)
    @faction.reload
    assert_equal "NEW_LIMITED_KEY", @faction.torn_api_key.key
    assert_equal "TORNSTATS_KEY", @faction.tornstats_api_key.key
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
    assert_equal "UPDATED_KEY", @faction.reload.torn_api_key.key
  end

  test "update_keys updates only tornstats key when no torn key provided" do
    sign_in_as(@bram)
    patch faction_leadership_api_keys_path(@faction), params: {
      faction_setting: { tornstats_api_key: "NEW_TORNSTATS_KEY" }
    }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /saved successfully/, flash[:notice]
    assert_equal "NEW_TORNSTATS_KEY", @faction.reload.tornstats_api_key.key
    assert_equal "FACTION_KEY", @faction.torn_api_key.key, "Torn key should be unchanged"
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

  test "delete_torn_key clears the torn api key and resets setup" do
    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "torn")

    assert_redirected_to faction_path(@faction)
    assert_match /deleted/, flash[:notice]

    assert_nil @faction.reload.torn_api_key
    assert_not @faction.setup_completed?
  end

  test "delete_torn_key handles no torn key gracefully" do
    @faction.torn_api_key&.destroy!

    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "torn")

    # Redirects to setup since no torn key exists (before_action check)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  # -- Delete TornStats Key --

  test "delete_tornstats_key clears the tornstats api key" do
    ApiKey::Tornstats.create!(faction: @faction, key: "SOME_KEY")

    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "tornstats")

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /deleted/, flash[:notice]
    assert_nil @faction.reload.tornstats_api_key
  end

  test "delete_tornstats_key handles no tornstats key gracefully" do
    sign_in_as(@bram)
    delete faction_leadership_api_keys_path(@faction, key: "tornstats")

    assert_redirected_to faction_leadership_settings_path(@faction)
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

  test "revoke_leadership_access prevents removing yourself" do
    sign_in_as(@bram)
    delete faction_leadership_leadership_access_path(@faction), params: { user_id: @bram.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert @bram.reload.leadership_access?
    assert_match /cannot remove your own access/, flash[:alert]
  end

  test "revoke_leadership_access prevents removing faction leader" do
    @bert.update!(position: "Leader")

    sign_in_as(@bram)
    delete faction_leadership_leadership_access_path(@faction), params: { user_id: @bert.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert @bert.reload.leadership_access?
    assert_match /Leader and cannot be removed/, flash[:alert]
  end

  test "revoke_leadership_access prevents removing co-leader" do
    @bert.update!(position: "Co-leader")

    sign_in_as(@bram)
    delete faction_leadership_leadership_access_path(@faction), params: { user_id: @bert.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert @bert.reload.leadership_access?
    assert_match /Co-leader and cannot be removed/, flash[:alert]
  end

  test "revoke_leadership_access handles user without access" do
    member = User.create!(torn_id: 555555, name: "NoAccess", level: 30, faction: @faction)

    sign_in_as(@bram)
    delete faction_leadership_leadership_access_path(@faction), params: { user_id: member.id }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /not found in leadership/, flash[:alert]
  end

  # -- Extend Faction Subscription --

  test "extend_faction_subscription extends faction subscription" do
    grant_subscription(@bram, expires_at: 52.weeks.from_now)

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 4 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /Extended faction subscription by 4 week/, flash[:notice]
  end

  test "extend_faction_subscription rejects zero weeks" do
    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 0 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /valid number/, flash[:alert]
  end

  test "extend_faction_subscription rejects negative weeks" do
    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: -5 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /valid number/, flash[:alert]
  end

  test "extend_faction_subscription rejects when user has insufficient weeks" do
    grant_subscription(@bram, expires_at: 1.week.from_now)

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 10 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /personal weeks/, flash[:alert]
  end

  test "extend_faction_subscription creates faction subscription grant record" do
    grant_subscription(@bram, expires_at: 52.weeks.from_now)

    sign_in_as(@bram)

    assert_difference "FactionSubscriptionGrant.count", 1 do
      post faction_leadership_subscriptions_path(@faction), params: { weeks: 4 }
    end

    grant = FactionSubscriptionGrant.last
    assert_equal @faction.torn_id, grant.torn_faction_id
    assert_equal @bram, grant.granted_by
    assert_equal 4, grant.weeks_granted
  end

  test "extend_faction_subscription deducts weeks from granting user" do
    grant_subscription(@bram, expires_at: 52.weeks.from_now)
    original_weeks = @bram.subscription_weeks_remaining

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 4 }

    remaining = @bram.reload.subscription_weeks_remaining
    assert remaining < original_weeks, "Personal subscription should be deducted"
  end

  test "extend_faction_subscription cost scales with member count" do
    # Add more members to increase the cost
    20.times do |i|
      User.create!(torn_id: 800000 + i, name: "Member#{i}", level: 10, faction: @faction)
    end
    # 22 members total (bram + bert + 20) -> ceil(22/4) = 6 personal weeks per faction week

    grant_subscription(@bram, expires_at: 52.weeks.from_now)
    original_weeks = @bram.subscription_weeks_remaining

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 2 }

    # 2 faction weeks * 6 cost = 12 personal weeks deducted
    deducted = original_weeks - @bram.reload.subscription_weeks_remaining
    assert_equal 12, deducted, "Should deduct 12 personal weeks (2 faction weeks * 6 cost)"
  end

  test "extend_faction_subscription creates new subscription when none exists" do
    @faction.subscription&.destroy!
    grant_subscription(@bram, expires_at: 52.weeks.from_now)

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 2 }

    assert @faction.reload.subscription.present?, "Faction should have a subscription"
    assert @faction.subscription.active?, "Faction subscription should be active"
  end

  test "extend_faction_subscription rejects cost exceeding personal balance" do
    # 2 members -> cost = 1 per faction week
    # Give bram only 3 weeks, request 5 faction weeks = 5 personal weeks
    grant_subscription(@bram, expires_at: 3.weeks.from_now)

    sign_in_as(@bram)
    post faction_leadership_subscriptions_path(@faction), params: { weeks: 5 }

    assert_redirected_to faction_leadership_settings_path(@faction)
    assert_match /personal weeks/, flash[:alert]
  end

  # -- Import Spies --

  test "import_spies imports spy reports from tornstats" do
    ApiKey::Tornstats.create!(faction: @faction, key: "TORNSTATS_KEY")

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
    ApiKey::Tornstats.create!(faction: @faction, key: "TORNSTATS_KEY")

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /enter a faction ID/, flash[:alert]
  end

  test "import_spies rejects when tornstats key not configured" do
    @faction.tornstats_api_key&.destroy!

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /TornStats API key must be configured/, flash[:alert]
  end

  test "import_spies enforces rate limiting" do
    ApiKey::Tornstats.create!(faction: @faction, key: "TORNSTATS_KEY")

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
    ApiKey::Tornstats.create!(faction: @faction, key: "TORNSTATS_KEY")
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).raises(TornStatsApi::NotFoundError, "No data")

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /No spy data found/, flash[:alert]
  end

  test "import_spies handles invalid key error" do
    ApiKey::Tornstats.create!(faction: @faction, key: "BAD_KEY")
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).raises(TornStatsApi::InvalidKeyError, "Bad key")

    sign_in_as(@bram)
    post faction_leadership_spy_imports_path(@faction), params: { target_faction_id: "88888" }

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /Invalid TornStats API key/, flash[:alert]
  end

  test "import_spies upserts existing spy reports" do
    ApiKey::Tornstats.create!(faction: @faction, key: "TORNSTATS_KEY")
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

  test "delete_faction_data preserves faction subscription" do
    sign_in_as(@bram)
    delete faction_leadership_faction_data_path(@faction)

    assert @faction.reload.subscription.present?,
      "Faction subscription should NOT be revoked"
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
    kaneki.update!(faction: @faction)

    sign_in_as(kaneki)
    get faction_leadership_path(@faction)

    assert_redirected_to faction_path(@faction)
  end

  test "member without leadership access cannot access mutating actions" do
    kaneki = users(:kaneki)
    kaneki.update!(faction: @faction)

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
