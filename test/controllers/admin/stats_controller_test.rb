require "test_helper"

class Admin::StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:bram)
    @bert = users(:bert)
    sign_in_as(@admin)
  end

  test "requires admin access" do
    sign_in_as(@bert)
    get admin_stats_path
    assert_redirected_to root_path
  end

  test "requires authentication" do
    sign_out
    get admin_stats_path
    assert_redirected_to new_session_path
  end

  test "renders all sections" do
    get admin_stats_path
    assert_response :success

    assert_select "h2", text: "Data Collection"
    assert_select "h2", text: "Torn API"
    assert_select "h2", text: "Factions"
    assert_select "h2", text: /Storage/
  end

  test "health strip renders verdict pills" do
    get admin_stats_path
    assert_response :success

    assert_select ".admin-hpill", minimum: 3
    assert_select ".admin-hpill b", text: "Collection"
    assert_select ".admin-hpill b", text: "Budget"
  end

  test "shows kpi tiles and user stats" do
    get admin_stats_path
    assert_response :success

    assert_select ".admin-kpi .k", text: "Tracked users"
    assert_select ".admin-kpi .k", text: "Active subs"
    assert_select ".admin-stat-label", text: "API keys"
    assert_select ".admin-stat-label", text: "HoF users"
  end

  test "shows faction stats with member table" do
    faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    @admin.update!(faction: faction)

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-table td", text: "Test Faction"
  end

  test "shows snapshot coverage stats" do
    PersonalStatSnapshot.create!(user: @admin, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stat-label", text: "Days with data"
  end

  test "shows api call stats with admin key breakdown" do
    ApiCall.create!(user: @admin, endpoint: "/test", status: "success", api_key: "ABCDEF")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stat-label", text: "Total calls"
    assert_select ".admin-stat-label", text: "Peak rate"
    assert_select ".admin-stat-label", text: "Peak today"
    assert_select ".admin-stat-label", text: "Admin key calls"
    assert_select ".admin-stat-label", text: "Admin peak rate"
    assert_select ".admin-stat-label", text: "Admin peak today"
  end

  test "admin api stats are scoped to admin credentials key" do
    admin_key = "ADMIN_SECRET_KEY"
    AdminCredentials.stubs(:api_key).returns(admin_key)

    ApiCall.create!(user: @admin, endpoint: "/admin", status: "success", api_key: admin_key)
    ApiCall.create!(user: @admin, endpoint: "/admin", status: "success", api_key: admin_key)
    ApiCall.create!(user: @bert, endpoint: "/faction", status: "success", api_key: "FACTION_KEY")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-sub .admin-stat-value", text: "2"
  end

  test "shows sign-in stats" do
    get admin_stats_path
    assert_response :success

    assert_select ".admin-stat-label", text: "Sessions this week"
  end

  test "shows first-time sign-ins table" do
    new_user = User.create!(torn_id: 999888, name: "NewPlayer", level: 10)
    Session.create!(user: new_user, ip_address: "1.2.3.4", user_agent: "test")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-table td a", text: /NewPlayer/
  end

  test "joined date shows first session date not user creation date" do
    new_user = User.create!(torn_id: 999888, name: "NewPlayer", level: 10, created_at: 1.year.ago)
    Session.create!(user: new_user, ip_address: "1.2.3.4", user_agent: "test", created_at: 2.days.ago)

    get admin_stats_path
    assert_response :success

    first_session_date = 2.days.ago.strftime("%d %b")
    user_created_date = 1.year.ago.strftime("%d %b")

    # Should show first session date
    assert_select "tr" do
      assert_select "a", text: /NewPlayer/
      assert_select "td", text: first_session_date
    end
    # Should NOT show user creation date
    assert_select "tr" do |rows|
      new_player_row = rows.find { |r| r.text.include?("NewPlayer") }
      assert_not_includes new_player_row.text, user_created_date if first_session_date != user_created_date
    end
  end

  test "does not show users with older sessions as first-time" do
    old_user = User.create!(torn_id: 999777, name: "OldPlayer", level: 10)
    Session.create!(user: old_user, ip_address: "1.2.3.4", user_agent: "test", created_at: 2.weeks.ago)
    Session.create!(user: old_user, ip_address: "1.2.3.4", user_agent: "test")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-table td a", text: /OldPlayer/, count: 0
  end

  test "shows daily snapshots chart" do
    PersonalStatSnapshot.create!(user: @admin, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    get admin_stats_path
    assert_response :success

    assert_select ".admin-chart-bar", minimum: 1
  end

  test "shows data health warning colors for missing data" do
    faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    @admin.update!(faction: faction)

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stat-value.warning"
  end

  test "renders with no data at all" do
    get admin_stats_path
    assert_response :success

    assert_select "h1", text: "System Stats"
  end

  test "api key breakdown peak reflects only the last 24 hours" do
    key = "PEAKWINDOWKEY123"
    # burst of 3 calls in one minute, two days ago — outside the 24h window
    travel_to 2.days.ago.change(min: 0, sec: 0) do
      3.times { ApiCall.create!(user: @admin, endpoint: "/test", status: "success", api_key: key) }
    end
    # two calls now, in different minutes — inside the window
    travel_to Time.current.change(sec: 0) do
      ApiCall.create!(user: @admin, endpoint: "/test", status: "success", api_key: key)
    end
    travel_to Time.current.change(sec: 0) + 1.minute do
      ApiCall.create!(user: @admin, endpoint: "/test", status: "success", api_key: key)
    end

    get admin_stats_path
    assert_response :success

    row = css_select(".admin-stats-table tr").find { |r| r.text.include?("PEAK...Y123") }
    assert row, "breakdown row for the key must render"
    assert_includes row.text, "1/min", "peak must come from the 24h window, not all history"
  end

  test "single-call keys are folded into one row" do
    # fixture key ABCDEF has exactly 1 call and 0 errors -> folded
    get admin_stats_path
    assert_response :success

    assert_select ".admin-folded td", text: /keys with 1 call/
    folded_away = css_select(".admin-stats-table tr").none? { |r| r.text.include?("ABCD...CDEF") }
    assert folded_away, "single-call keys must not get their own row"
  end

  test "abandoned factions show a stale chip" do
    faction = Faction.create!(torn_id: 88888, name: "Ghost Crew", xanax_target: 2.5, setup_completed: false)
    faction.update_column(:updated_at, 40.days.ago)

    get admin_stats_path
    assert_response :success

    row = css_select(".admin-stats-table tr").find { |r| r.text.include?("Ghost Crew") }
    assert row, "faction row must render"
    assert_match(/stale 40d/, row.text)
  end

  test "completeness counts partially-filled snapshots as incomplete" do
    PersonalStatSnapshot.delete_all
    PersonalStatSnapshot.create!(
      user: @admin, date: 3.days.ago.to_date,
      drugs_xanax: 1, items_used_energy_drinks: 1, other_refills_energy: 1,
      other_refills_nerve: 1, items_used_boosters: 1, items_used_stat_enhancers: 1,
      missions_contracts_total: 1, crimes_offenses_total: 1, other_activity_time: 1,
      networth_total: 1, attacking_networth_money_mugged: 1
    )
    PersonalStatSnapshot.create!(user: @bert, date: 3.days.ago.to_date, drugs_xanax: 5)

    get admin_stats_path
    assert_response :success

    row = css_select(".admin-stat-row").find { |r| r.text.include?("Complete / incomplete") }
    assert_includes row.css(".admin-stat-value").text, "1 / 1",
      "a row missing batch-2 columns must count as incomplete"
  end

  test "gap stats are computed correctly" do
    PersonalStatSnapshot.stubs(:tracking_start_date).returns(Date.new(2024, 1, 1))
    PersonalStatSnapshot.stubs(:tracking_end_date).returns(Date.new(2024, 1, 2))

    gapless = User.create!(torn_id: 555_111, name: "Gapless", level: 5, hof_stats_user: true)
    gapless.personal_stat_snapshots.create!(date: Date.new(2024, 1, 1))
    gapless.personal_stat_snapshots.create!(date: Date.new(2024, 1, 2))

    tracked_count = User.tracked_for_stats.count

    get admin_stats_path
    assert_response :success

    # every tracked user except Gapless misses both window days
    gap_row = css_select(".admin-stat-row").find { |r| r.text.include?("Users with gaps") }
    assert_equal (tracked_count - 1).to_s, gap_row.css(".admin-stat-value").text.strip

    missing_row = css_select(".admin-stat-row").find { |r| r.text.include?("Total missing days") }
    assert_equal ((tracked_count - 1) * 2).to_s, missing_row.css(".admin-stat-value").text.strip
  end
end
