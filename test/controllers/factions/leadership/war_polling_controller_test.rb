require "test_helper"

class Factions::Leadership::WarPollingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5, setup_completed: true)
    @bram = users(:bram)
    @bram.update!(faction: @faction, leadership_access: true, subscription_expires_at: 1.month.from_now)
    @faction.create_faction_setting!(torn_api_key: "faction_limited_key", torn_api_access_type: "Limited Access")
  end

  test "start activates war polling when active war exists" do
    create_active_war

    sign_in_as(@bram)

    assert_enqueued_with(job: WarPollingJob, args: [ @faction.id ]) do
      post start_faction_leadership_war_polling_path(@faction)
    end

    assert @faction.reload.war_polling_active?
    assert_redirected_to faction_leadership_path(@faction)
    assert_equal "War polling started.", flash[:notice]
  end

  test "start redirects with alert when no active war" do
    sign_in_as(@bram)

    post start_faction_leadership_war_polling_path(@faction)

    assert_not @faction.reload.war_polling_active?
    assert_redirected_to faction_leadership_path(@faction)
    assert_match /No active ranked war/, flash[:alert]
  end

  test "start redirects to setup when no torn api key configured" do
    @faction.faction_setting.update!(torn_api_key: nil)
    create_active_war
    sign_in_as(@bram)

    post start_faction_leadership_war_polling_path(@faction)

    assert_redirected_to setup_faction_leadership_path(@faction)
  end

  test "stop deactivates war polling" do
    @faction.update!(war_polling_active: true)
    sign_in_as(@bram)

    with_memory_cache do
      Rails.cache.write(@faction.war_cache_key, { some: "data" })

      delete stop_faction_leadership_war_polling_path(@faction)

      assert_not @faction.reload.war_polling_active?
      assert_nil Rails.cache.read(@faction.war_cache_key)
      assert_redirected_to faction_leadership_path(@faction)
      assert_equal "War polling stopped.", flash[:notice]
    end
  end

  test "requires leadership access" do
    bert = users(:bert)
    bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    sign_in_as(bert)
    post start_faction_leadership_war_polling_path(@faction)

    assert_redirected_to faction_path(@faction)
  end

  test "requires authentication" do
    post start_faction_leadership_war_polling_path(@faction)
    assert_redirected_to new_session_path
  end

  private

  def create_active_war
    @faction.ranked_wars.create!(
      torn_war_id: 1001,
      opponent_faction_id: 88888,
      opponent_faction_name: "Enemy Faction",
      started_at: 1.hour.ago,
      target_score: 100,
      our_score: 30,
      their_score: 20
    )
  end

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
