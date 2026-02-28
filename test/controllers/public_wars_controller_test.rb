require "test_helper"

class PublicWarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @open_lobby = public_war_lobbies(:open_lobby)
    @locked_lobby = public_war_lobbies(:locked_lobby)
  end

  # -- Index --

  test "index is accessible without authentication" do
    get public_wars_path
    assert_response :success
  end

  test "index lists lobbies" do
    get public_wars_path
    assert_response :success
    assert_select ".public-war-card", minimum: 1
  end

  test "index shows create form" do
    get public_wars_path
    assert_response :success
    assert_select ".public-wars-create-form"
    assert_select "input[name='accept_terms']"
  end

  test "index shows locked lobbies as non-link cards with modal trigger" do
    get public_wars_path
    assert_response :success
    assert_select ".public-war-card--locked[data-action*='lobby-unlock#open']", minimum: 1
  end

  test "index includes password unlock modal" do
    get public_wars_path
    assert_response :success
    assert_select ".public-war-modal-backdrop"
    assert_select ".public-war-modal"
  end

  # -- Show --

  test "show renders open lobby without authentication" do
    get public_war_path(@open_lobby)
    assert_response :success
  end

  test "show redirects to index for locked lobby" do
    get public_war_path(@locked_lobby)
    assert_redirected_to public_wars_path
    assert_match /password protected/, flash[:alert]
  end

  test "show renders dashboard when locked lobby is unlocked via session" do
    post unlock_public_war_path(@locked_lobby), params: { password: "secret" }
    assert_redirected_to public_war_path(@locked_lobby)

    get public_war_path(@locked_lobby)
    assert_response :success
  end

  test "show redirects when lobby does not exist" do
    get public_war_path(slug: "nonexistent")
    assert_redirected_to public_wars_path
    assert_match /terminated/, flash[:alert]
  end

  # -- War data (JSON endpoint) --

  test "war_data returns cached data as JSON" do
    with_memory_cache do
      war_data = { faction_name: "Test Faction", members: {}, cached_at: Time.current.iso8601 }
      Rails.cache.write(@open_lobby.war_cache_key, war_data)

      get war_data_public_war_path(@open_lobby)
      assert_response :success
      assert_equal "application/json", response.media_type

      json = JSON.parse(response.body)
      assert_equal "Test Faction", json["faction_name"]
    end
  end

  test "war_data returns no_content when cache is empty" do
    with_memory_cache do
      get war_data_public_war_path(@open_lobby)
      assert_response :no_content
    end
  end

  test "war_data returns 410 gone for terminated lobby" do
    get war_data_public_war_path(slug: "nonexistent"), headers: { "Accept" => "application/json" }
    assert_response :gone

    json = JSON.parse(response.body)
    assert json["terminated"]
  end

  test "index shows terminated message when redirected from deleted lobby" do
    get public_wars_path(terminated: 1)
    assert_response :success
    assert_match /terminated/, flash[:alert]
  end

  # -- Unlock (HTML) --

  test "unlock with correct password redirects to show" do
    post unlock_public_war_path(@locked_lobby), params: { password: "secret" }
    assert_redirected_to public_war_path(@locked_lobby)
  end

  test "unlock with incorrect password re-renders index with error" do
    post unlock_public_war_path(@locked_lobby), params: { password: "wrong" }
    assert_response :unprocessable_entity
    assert_match /Incorrect password/, flash[:alert]
    assert_select ".public-wars-create-form"
  end

  # -- Unlock (JSON / AJAX) --

  test "unlock via JSON with correct password returns redirect URL" do
    post unlock_public_war_path(@locked_lobby),
      params: { password: "secret" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal public_war_path(@locked_lobby), json["redirect_to"]
  end

  test "unlock via JSON with incorrect password returns error" do
    post unlock_public_war_path(@locked_lobby),
      params: { password: "wrong" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Incorrect password.", json["error"]
  end

  # -- Create: validation errors --

  test "create requires terms acceptance" do
    post public_wars_path, params: { api_key: "SOMEKEY", faction_torn_id: 12345 }
    assert_response :unprocessable_entity
    assert_match /Terms of Service/, flash[:alert]
  end

  test "create requires api key" do
    post public_wars_path, params: { api_key: "", faction_torn_id: 12345, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /API key is required/, flash[:alert]
  end

  test "create requires faction torn id" do
    post public_wars_path, params: { api_key: "SOMEKEY", faction_torn_id: 0, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /Faction Torn ID is required/, flash[:alert]
  end

  test "create rejects invalid API key" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid key")

    post public_wars_path, params: { api_key: "BAD_KEY", faction_torn_id: 12345, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /Invalid API key/, flash[:alert]
  end

  test "create rejects non-public API keys" do
    stub_limited_key_and_profile

    post public_wars_path, params: { api_key: "LIMITED_KEY", faction_torn_id: 12345, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /Public Only/, flash[:alert]
  end

  test "create rejects when faction not found" do
    stub_valid_key_and_profile

    TornApi::Faction::Basic.any_instance.stubs(:fetch).raises(TornApi::NotFoundError, "Not found")

    post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: 12345, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /Faction not found/, flash[:alert]
  end

  test "create rejects when no active ranked war" do
    stub_valid_key_and_profile
    stub_faction_basic("Test Faction")

    TornApi::Faction::RankedWars.any_instance.stubs(:fetch).returns([
      { "end" => 1708000000, "factions" => [ { "id" => 12345, "name" => "Test" }, { "id" => 67890, "name" => "Enemy" } ] }
    ])

    post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: 12345, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /No active ranked war/, flash[:alert]
  end

  test "create rejects duplicate faction lobby" do
    stub_valid_key_and_profile
    stub_faction_basic("Test Faction")
    stub_active_ranked_war(99999, "Enemy Faction")

    post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: @open_lobby.faction_torn_id, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /already exists/, flash[:alert]
  end

  test "create rejects when lobby limit is reached" do
    PublicWarLobby.delete_all

    PublicWarLobby::MAX_LOBBIES.times do |i|
      PublicWarLobby.create!(
        faction_torn_id: 10000 + i,
        faction_name: "Faction #{i}",
        opponent_faction_name: "Opponent #{i}",
        created_by_name: "Creator #{i}",
        created_by_torn_id: 1000000 + i
      )
    end

    post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: 54321, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_match /Maximum/, flash[:alert]
  end

  # -- Create: success --

  test "create succeeds with valid public key" do
    stub_valid_key_and_profile
    stub_faction_basic("New Faction")
    stub_active_ranked_war(54321, "New Enemy")

    with_memory_cache do
      assert_difference "PublicWarLobby.count", 1 do
        post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: 54321, accept_terms: "1" }
      end

      lobby = PublicWarLobby.last
      assert_redirected_to public_war_path(lobby)
      assert_equal "New Faction", lobby.faction_name
      assert_equal "New Enemy", lobby.opponent_faction_name
      assert_equal "TestCreator", lobby.created_by_name
      assert_equal 1111111, lobby.created_by_torn_id
      assert_not lobby.password_protected?

      assert_equal "VALID_KEY", Rails.cache.read(lobby.api_key_cache_key)
    end
  end

  test "create with password sets password digest" do
    stub_valid_key_and_profile
    stub_faction_basic("New Faction")
    stub_active_ranked_war(54321, "New Enemy")

    with_memory_cache do
      post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: 54321, password: "mysecret", accept_terms: "1" }

      lobby = PublicWarLobby.last
      assert lobby.password_protected?
      assert lobby.authenticate("mysecret")
    end
  end

  test "create enqueues polling job" do
    stub_valid_key_and_profile
    stub_faction_basic("New Faction")
    stub_active_ranked_war(54321, "New Enemy")

    with_memory_cache do
      assert_enqueued_with(job: PublicWarPollingJob) do
        post public_wars_path, params: { api_key: "VALID_KEY", faction_torn_id: 54321, accept_terms: "1" }
      end
    end
  end

  test "create error re-renders index with lobbies" do
    post public_wars_path, params: { api_key: "", faction_torn_id: 12345, accept_terms: "1" }
    assert_response :unprocessable_entity
    assert_select ".public-wars-create-form"
  end

  # -- Destroy --

  test "destroy with correct confirmation terminates lobby" do
    with_memory_cache do
      Rails.cache.write(@open_lobby.war_cache_key, { some: "data" })
      Rails.cache.write(@open_lobby.api_key_cache_key, "api_key_value")

      assert_difference "PublicWarLobby.count", -1 do
        delete public_war_path(@open_lobby), params: { confirmation: "terminate" }
      end

      assert_redirected_to public_wars_path
      assert_match /terminated/, flash[:notice]
    end
  end

  test "destroy with incorrect confirmation re-renders show with error" do
    delete public_war_path(@open_lobby), params: { confirmation: "wrong text" }
    assert_response :unprocessable_entity
    assert_match /Confirmation text did not match/, flash[:alert]
  end

  test "destroy confirmation is case-insensitive" do
    with_memory_cache do
      assert_difference "PublicWarLobby.count", -1 do
        delete public_war_path(@open_lobby), params: { confirmation: "TERMINATE" }
      end

      assert_redirected_to public_wars_path
    end
  end

  private

  def stub_valid_key_and_profile
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: "Public Only", faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: 1111111, faction_id: 12345, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    profile = TornApi::User::Profile::ProfileData.new(
      id: 1111111, name: "TestCreator", level: 50, image: nil
    )
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(profile)
  end

  def stub_limited_key_and_profile
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 1111111, faction_id: 12345, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    profile = TornApi::User::Profile::ProfileData.new(
      id: 1111111, name: "TestCreator", level: 50, image: nil
    )
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(profile)
  end

  def stub_faction_basic(name)
    TornApi::Faction::Basic.any_instance.stubs(:fetch).returns({ "name" => name })
  end

  def stub_active_ranked_war(faction_torn_id, opponent_name)
    TornApi::Faction::RankedWars.any_instance.stubs(:fetch).returns([
      {
        "end" => 0,
        "factions" => [
          { "id" => faction_torn_id, "name" => "Tracked Faction" },
          { "id" => 99990, "name" => opponent_name }
        ]
      }
    ])
  end

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
