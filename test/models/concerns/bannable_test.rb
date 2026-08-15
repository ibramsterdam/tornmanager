require "test_helper"

class BannableTest < ActiveSupport::TestCase
  setup { @user = users(:bram) }

  test "ban! with no duration bans effectively forever" do
    @user.ban!
    assert @user.banned?
    assert @user.banned_until > 100.years.from_now
  end

  test "ban! with a duration expires on its own" do
    @user.ban!(24.hours)
    assert @user.banned?

    travel 25.hours do
      assert_not @user.banned?
    end
  end

  test "unban! clears the ban" do
    @user.ban!
    @user.unban!
    assert_not @user.banned?
    assert_nil @user.banned_until
  end

  test "ban! accepts a specific end time and a reason" do
    @user.ban!(Time.utc(2026, 9, 1), reason: "Scamming in The Lounge")

    assert @user.banned?
    assert_equal Time.utc(2026, 9, 1), @user.banned_until
    assert_equal "Scamming in The Lounge", @user.banned_reason
  end

  test "unban! clears the reason too" do
    @user.ban!(2.weeks, reason: "Spam")
    @user.unban!

    assert_nil @user.banned_reason
  end

  test "ban_message includes the end date and reason for temporary bans" do
    @user.ban!(Time.utc(2026, 9, 1), reason: "Scamming")

    assert_equal "Your access to TornManager has been suspended until 1 September 2026. Reason: Scamming.", @user.ban_message
  end

  test "ban_message omits the date for permanent bans" do
    @user.ban!(reason: "CSAM")

    assert_equal "Your access to TornManager has been suspended. Reason: CSAM.", @user.ban_message
  end

  test "ban_message without a reason" do
    @user.ban!

    assert_equal "Your access to TornManager has been suspended.", @user.ban_message
  end

  test "banned and not_banned scopes" do
    @user.ban!
    other = users(:bert)
    other.unban!

    assert_includes User.banned, @user
    assert_not_includes User.banned, other
    assert_includes User.not_banned, other
    assert_not_includes User.not_banned, @user
  end
end
