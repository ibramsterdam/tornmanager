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

  test "renders all panels" do
    get admin_stats_path
    assert_response :success

    assert_select "h2", text: "Users"
    assert_select "h2", text: "Factions"
    assert_select "h2", text: "Snapshots"
    assert_select "h2", text: "Activity"
    assert_select "h2", text: /Torn API/
    assert_select "h2", text: "Data Health"
    assert_select "h2", text: /Sign-ins/
  end

  test "shows user stats" do
    get admin_stats_path
    assert_response :success

    assert_select ".admin-stat-label", text: "Total"
    assert_select ".admin-stat-label", text: "Subscribers"
    assert_select ".admin-stat-label", text: "API Keys"
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

    assert_select ".admin-stat-label", text: "Days with Data"
  end

  test "shows api call stats with admin key breakdown" do
    ApiCall.create!(user: @admin, endpoint: "/test", status: "success", api_key: "ABCDEF")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stat-label", text: "Total calls"
    assert_select ".admin-stat-label", text: "Peak rate"
    assert_select ".admin-stat-label", text: "Peak rate today"
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
    assert_select ".admin-stat-label", text: "Unique users"
    assert_select ".admin-stat-label", text: "First-time users"
  end

  test "shows first-time sign-ins table" do
    new_user = User.create!(torn_id: 999888, name: "NewPlayer", level: 10)
    Session.create!(user: new_user, ip_address: "1.2.3.4", user_agent: "test")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-table td a", text: /NewPlayer/
  end

  test "does not show users with older sessions as first-time" do
    old_user = User.create!(torn_id: 999777, name: "OldPlayer", level: 10)
    Session.create!(user: old_user, ip_address: "1.2.3.4", user_agent: "test", created_at: 2.weeks.ago)
    Session.create!(user: old_user, ip_address: "1.2.3.4", user_agent: "test")

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-table td a", text: /OldPlayer/, count: 0
  end

  test "shows daily snapshots table" do
    PersonalStatSnapshot.create!(user: @admin, date: Date.yesterday, timestamp: Date.yesterday.to_time.to_i)

    get admin_stats_path
    assert_response :success

    assert_select ".admin-stats-table th", text: "Snapshots"
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
end
