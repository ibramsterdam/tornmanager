require "test_helper"

class UserCompanyAccessTest < ActiveSupport::TestCase
  setup do
    @user = users(:bert)
    @user.update!(company_director: true)
    @user.set_company_api_key!("COMPANY_KEY", "Limited Access")
    grant_subscription(@user, expires_at: 1.week.from_now)
  end

  test "a subscribed director with a key has access" do
    assert @user.company_access?
  end

  test "no access without a subscription" do
    @user.subscription.update!(expires_at: 1.day.ago)

    assert_not @user.reload.company_access?
  end

  test "the admin needs no subscription" do
    admin = users(:bram)
    admin.update!(company_director: true)
    admin.set_company_api_key!("ADMIN_COMPANY_KEY", "Limited Access")

    assert admin.company_access?
  end

  test "no access when turned off" do
    @user.update!(company_access_disabled: true)

    assert_not @user.company_access?
  end

  test "no access when no longer the director" do
    @user.update!(company_director: false)

    assert_not @user.company_access?
  end

  test "no access without a key" do
    @user.company_api_key.destroy!

    assert_not @user.reload.company_access?
  end
end
