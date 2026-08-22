require "test_helper"

class Api::RecruiterMatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    grant_subscription(@bram, expires_at: 1.week.from_now)

    @bert = users(:bert)
    @bert.update!(faction_torn_id: 46166)
    companies(:adult_novelties).update!(director_faction_torn_id: 46166, synced_at: 2.hours.ago)
    @kaneki = users(:kaneki)
    @kaneki.update!(company_id: 91002, working_stats: 500_000, working_stats_at: 3.hours.ago)
    users(:user_no_faction).update!(company_id: 91003, working_stats: 50_000)
    users(:user_hof_no_faction).update!(company_id: 91001, company_director: true, working_stats: 999_999)
  end

  test "requires an active subscription" do
    post api_recruiter_matches_path, params: {}, headers: api_auth(users(:bert)), as: :json

    assert_response :forbidden
    assert JSON.parse(response.body)["subscription_required"]
  end

  test "requires a session token" do
    post api_recruiter_matches_path, params: {}, as: :json

    assert_response :unauthorized
  end

  test "returns matches sorted by working stats with company and faction data" do
    post api_recruiter_matches_path,
      params: { type_ids: [ 10, 26 ], star_min: 8, star_max: 10, min_stats: 1 },
      headers: api_auth(@bram), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["total"]
    assert_equal [ @kaneki.torn_id, @bert.torn_id ], json["matches"].map { |m| m["torn_id"] }

    bert_match = json["matches"].last
    assert_equal 250_000, bert_match["working_stats"]
    assert bert_match["faction_mate_of_director"]
    assert_equal "Pleasure Dome", bert_match.dig("company", "name")
    assert_equal 9, bert_match.dig("company", "rating")

    assert_not json["matches"].first["faction_mate_of_director"]
    assert_not_nil json.dig("meta", "roster_synced_at")
  end

  test "excludes faction mates of the director on request" do
    post api_recruiter_matches_path,
      params: { star_min: 0, star_max: 10, exclude_faction_mates: true },
      headers: api_auth(@bram), as: :json

    json = JSON.parse(response.body)
    torn_ids = json["matches"].map { |m| m["torn_id"] }
    assert_not_includes torn_ids, @bert.torn_id
    assert_includes torn_ids, @kaneki.torn_id
    assert_equal 2, json["total"]
  end

  test "excludes directors" do
    post api_recruiter_matches_path,
      params: { star_min: 0, star_max: 10 },
      headers: api_auth(@bram), as: :json

    torn_ids = JSON.parse(response.body)["matches"].map { |m| m["torn_id"] }
    assert_not_includes torn_ids, users(:user_hof_no_faction).torn_id
  end

  test "filters by minimum working stats" do
    post api_recruiter_matches_path,
      params: { star_min: 0, star_max: 10, min_stats: 300_000 },
      headers: api_auth(@bram), as: :json

    json = JSON.parse(response.body)
    assert_equal [ @kaneki.torn_id ], json["matches"].map { |m| m["torn_id"] }
  end

  test "filters by company type" do
    post api_recruiter_matches_path,
      params: { type_ids: [ 10 ], star_min: 0, star_max: 10 },
      headers: api_auth(@bram), as: :json

    json = JSON.parse(response.body)
    assert_equal [ @bert.torn_id ], json["matches"].map { |m| m["torn_id"] }
  end

  test "paginates past the results" do
    post api_recruiter_matches_path,
      params: { star_min: 0, star_max: 10, page: 5 },
      headers: api_auth(@bram), as: :json

    json = JSON.parse(response.body)
    assert_empty json["matches"]
    assert_equal 3, json["total"]
  end
end
