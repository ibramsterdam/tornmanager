require "test_helper"

class Discord::VerifierTest < ActiveSupport::TestCase
  test "lookup_torn_user returns data when discord is linked" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Discord.any_instance.stubs(:fetch).returns(
      TornApi::User::Discord::DiscordData.new(discord_id: "123456", user_id: 2728237)
    )

    verifier = Discord::Verifier.allocate
    result = verifier.send(:lookup_torn_user, "123456")

    assert_equal 2728237, result.user_id
  end

  test "lookup_torn_user returns nil when not linked" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Discord.any_instance.stubs(:fetch).returns(nil)

    verifier = Discord::Verifier.allocate
    result = verifier.send(:lookup_torn_user, "999999")

    assert_nil result
  end

  test "lookup_torn_user returns nil when no api key" do
    AdminCredentials.stubs(:api_key).returns(nil)

    verifier = Discord::Verifier.allocate
    result = verifier.send(:lookup_torn_user, "123456")

    assert_nil result
  end

  test "fetch_torn_name returns name from local database" do
    user = users(:bram)

    verifier = Discord::Verifier.allocate
    result = verifier.send(:fetch_torn_name, user.torn_id)

    assert_equal "Bram", result
  end

  test "fetch_torn_name returns Player when not in database and no api key" do
    AdminCredentials.stubs(:api_key).returns(nil)

    verifier = Discord::Verifier.allocate
    result = verifier.send(:fetch_torn_name, 9999999)

    assert_equal "Player", result
  end
end
