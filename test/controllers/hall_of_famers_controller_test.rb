require "test_helper"

class HallOfFamersControllerTest < ActionDispatch::IntegrationTest
  # ── Authorization ──

  test "redirects to login when not authenticated" do
    get hall_of_famers_path
    assert_redirected_to new_session_path
  end

  test "denies access to regular users" do
    sign_in_as(users(:bert))
    get hall_of_famers_path

    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
  end

  test "allows access for admin" do
    sign_in_as(users(:bram))
    get hall_of_famers_path
    assert_response :success
  end

  test "allows access for HoF owner" do
    sign_in_as(users(:kaneki))
    get hall_of_famers_path
    assert_response :success
  end

  # ── Index page ──

  test "index renders page with date filter and sortable table" do
    sign_in_as(users(:bram))
    get hall_of_famers_path

    assert_select "h1", "Hall of Famers"
    assert_select "input[name='start_date']"
    assert_select "input[name='end_date']"
    assert_select "table"
  end

  test "index counts days inclusively" do
    sign_in_as(users(:bram))
    get hall_of_famers_path, params: { start_date: "2026-01-01", end_date: "2026-01-10" }

    assert_match /10 days/, response.body
  end

  test "invalid sort column falls back to default without error" do
    sign_in_as(users(:bram))
    get hall_of_famers_path, params: { sort: "malicious_column" }
    assert_response :success
  end

  # ── Data display ──

  test "shows user gains calculated from day-before baseline" do
    user = users(:kaneki)
    user.update!(hof_stats_user: true)

    start_date = Date.new(2026, 1, 1)
    end_date = Date.new(2026, 1, 11)

    user.personal_stat_snapshots.create!(date: start_date - 1.day, timestamp: 0, drugs_xanax: 100, items_used_energy_drinks: 50, items_used_stat_enhancers: 200, networth_total: 1_000_000)
    user.personal_stat_snapshots.create!(date: end_date, timestamp: 0, drugs_xanax: 150, items_used_energy_drinks: 75, items_used_stat_enhancers: 250, networth_total: 2_000_000)

    sign_in_as(users(:bram))
    get hall_of_famers_path, params: { start_date: start_date.to_s, end_date: end_date.to_s }

    assert_match /Kaneki/, response.body
    assert_match /50/, response.body           # xanax gained
    assert_match /25/, response.body           # energy drinks gained
    assert_select "button.copy-stats-button[data-controller='clipboard']"
  end

  test "skips users with insufficient snapshot data" do
    user = users(:kaneki)
    user.update!(hof_stats_user: true)

    # Only one snapshot — not enough for gains calculation
    user.personal_stat_snapshots.create!(date: PersonalStatSnapshot.tracking_start_date, timestamp: 0, drugs_xanax: 100)

    sign_in_as(users(:bram))
    get hall_of_famers_path

    assert_no_match(/Kaneki/, response.body)
  end
end
