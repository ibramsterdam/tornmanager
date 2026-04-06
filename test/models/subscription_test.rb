require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "active? returns true when not expired" do
    sub = Subscription.new(expires_at: 1.week.from_now)
    assert sub.active?
  end

  test "active? returns false when expired" do
    sub = Subscription.new(expires_at: 1.day.ago)
    assert_not sub.active?
  end

  test "days_remaining returns positive days when active" do
    sub = Subscription.new(expires_at: 10.days.from_now)
    assert_equal 10, sub.days_remaining
  end

  test "days_remaining returns 0 when expired" do
    sub = Subscription.new(expires_at: 1.day.ago)
    assert_equal 0, sub.days_remaining
  end

  test "extend! adds weeks to active subscription" do
    faction = Faction.create!(torn_id: 99999, name: "Test", xanax_target: 2.5)
    sub = Subscription.create!(subscribable: faction, expires_at: 1.week.from_now)

    sub.extend!(2)
    assert_in_delta 3.weeks.from_now, sub.expires_at, 5.seconds
  end

  test "extend! starts from now when expired" do
    faction = Faction.create!(torn_id: 99998, name: "Expired", xanax_target: 2.5)
    sub = Subscription.create!(subscribable: faction, expires_at: 1.day.ago)

    sub.extend!(1)
    assert_in_delta 1.week.from_now, sub.expires_at, 5.seconds
  end

  test "can belong to a faction" do
    faction = Faction.create!(torn_id: 99997, name: "Faction Sub", xanax_target: 2.5)
    sub = Subscription.create!(subscribable: faction, expires_at: 1.month.from_now)

    assert_equal faction, sub.subscribable
    assert_equal sub, faction.subscription
  end

  test "can belong to a user" do
    user = users(:bram)
    sub = Subscription.create!(subscribable: user, expires_at: 1.month.from_now)

    assert_equal user, sub.subscribable
    assert_equal sub, user.subscription
  end

  test "enforces one subscription per subscribable" do
    faction = Faction.create!(torn_id: 99996, name: "Dupe Test", xanax_target: 2.5)
    Subscription.create!(subscribable: faction, expires_at: 1.month.from_now)

    assert_raises(ActiveRecord::RecordInvalid) do
      Subscription.create!(subscribable: faction, expires_at: 2.months.from_now)
    end
  end

  test "user.subscribed? checks personal subscription" do
    user = users(:bert)
    assert_not user.subscribed?

    grant_subscription(user, expires_at: 1.week.from_now)
    assert user.reload.subscribed?
  end

  test "user.subscribed? checks faction subscription" do
    faction = Faction.create!(torn_id: 99995, name: "Sub Faction", xanax_target: 2.5)
    user = users(:kaneki)
    user.update!(faction: faction)

    assert_not user.subscribed?

    grant_subscription(faction, expires_at: 1.week.from_now)
    assert user.reload.subscribed?
  end

  test "user.subscribed? prefers faction subscription when personal is expired" do
    faction = Faction.create!(torn_id: 99994, name: "Faction Wins", xanax_target: 2.5)
    user = users(:kaneki)
    user.update!(faction: faction)

    grant_subscription(user, expires_at: 1.day.ago)
    assert_not user.subscribed?

    grant_subscription(faction, expires_at: 1.month.from_now)
    assert user.reload.subscribed?
  end
end
