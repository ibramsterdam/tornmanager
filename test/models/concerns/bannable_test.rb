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
