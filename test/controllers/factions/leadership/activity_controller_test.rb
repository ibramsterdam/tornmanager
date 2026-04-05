require "test_helper"

class Factions::Leadership::ActivityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now, leadership_access: true)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
  end

  test "requires authentication" do
    get faction_leadership_activity_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_activity_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "redirects with notice when not enough data" do
    sign_in_as(@bram)
    get faction_leadership_activity_path(@faction)
    assert_redirected_to faction_leadership_path(@faction)
    assert_match /still being collected/, flash[:notice]
  end

  test "redirects when under 96 polls" do
    create_snapshots(10)
    sign_in_as(@bram)
    get faction_leadership_activity_path(@faction)
    assert_redirected_to faction_leadership_path(@faction)
  end

  test "shows real data when enough polls" do
    create_snapshots(100)
    sign_in_as(@bram)
    get faction_leadership_activity_path(@faction)
    assert_response :success
    assert_select "table.activity-heatmap"
    assert_select ".activity-member-timeline"
  end

  test "redirects to setup when no api keys" do
    @faction.torn_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_activity_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  private

  def create_snapshots(count)
    now = Time.current
    count.times do |i|
      MemberActivitySnapshot.create!(
        faction: @faction,
        torn_member_id: @bram.torn_id,
        member_name: @bram.name,
        recorded_at: now - (i * 15).minutes,
        hour_utc: (now - (i * 15).minutes).hour,
        day_of_week: (now - (i * 15).minutes).wday,
        status: %w[Online Idle Offline].sample
      )
    end
  end
end
