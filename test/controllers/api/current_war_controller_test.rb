require "test_helper"

class Api::CurrentWarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    @bram = users(:bram)
    @bram.update!(faction: @faction)
  end

  test "returns war data from cache" do
    war_data = {
      enemy_faction_id: 88888,
      enemy_faction_name: "Enemy Faction",
      our_score: 30,
      their_score: 20,
      target_score: 100,
      members: {}
    }

    with_memory_cache do
      Rails.cache.write(@faction.war_cache_key, war_data)

      post api_current_war_path, headers: api_auth(@bram), as: :json

      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal 88888, json.dig("war", "enemy_faction_id")
      assert_equal "Enemy Faction", json.dig("war", "enemy_faction_name")
      assert_equal 30, json.dig("war", "our_score")
    end
  end

  test "returns null war when cache is empty" do
    with_memory_cache do
      post api_current_war_path, headers: api_auth(@bram), as: :json

      assert_response :ok
      json = JSON.parse(response.body)
      assert_nil json["war"]
    end
  end

  test "returns error when token is missing" do
    post api_current_war_path, params: {}, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Session token is required. Please sign in again.", json["error"]
  end

  test "returns error for unknown token" do
    post api_current_war_path, headers: { "Authorization" => "Bearer nonexistent_token" }, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_match /Unknown session/, json["error"]
  end

  test "returns error when user has no faction" do
    @bram.update!(faction: nil)

    post api_current_war_path, headers: api_auth(@bram), as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match /not a member of any faction/, json["error"]
  end

  private

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
