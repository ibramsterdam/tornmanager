require "test_helper"

class Recon::TornApi::ProfileTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_key"
    @player_id = 123456
  end

  test "fetches profile data for a player" do
    api_response = {
      "profile" => {
        "age" => 4500,
        "level" => 80,
        "property" => { "id" => 123, "name" => "Private Island" },
        "last_action" => { "status" => "Online", "timestamp" => 1711500000 }
      }
    }

    service = Recon::TornApi::Profile.new(@api_key, @player_id)
    service.expects(:get).with("v2/user/#{@player_id}/profile", {}).returns(api_response)

    result = service.fetch
    assert_equal 4500, result.age
    assert_equal 80, result.level
    assert_equal "Private Island", result.property
    assert_equal 1711500000, result.last_action_timestamp
  end

  test "handles missing last_action gracefully" do
    api_response = {
      "profile" => {
        "age" => 1000,
        "level" => 15,
        "property" => { "id" => 1, "name" => "Apartment" },
        "last_action" => nil
      }
    }

    service = Recon::TornApi::Profile.new(@api_key, @player_id)
    service.expects(:get).returns(api_response)

    result = service.fetch
    assert_nil result.last_action_timestamp
  end

  test "handles missing property" do
    api_response = {
      "profile" => {
        "age" => 1000,
        "level" => 15,
        "property" => nil,
        "last_action" => { "timestamp" => 1711500000 }
      }
    }

    service = Recon::TornApi::Profile.new(@api_key, @player_id)
    service.expects(:get).returns(api_response)

    result = service.fetch
    assert_nil result.property
  end
end
