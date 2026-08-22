require "test_helper"

class Recruiter::KeyPoolTest < ActiveSupport::TestCase
  test "prefers a consented pool key" do
    key = api_keys(:bram_personal_key)
    key.update!(recruiter_fetch_allowed: true)

    assert_equal key.key, Recruiter::KeyPool.next_key
  end

  test "falls back to the credentials key when nobody consented" do
    Rails.application.credentials.stubs(:dig).with(:recruiter, :api_key).returns("service_key")

    assert_equal "service_key", Recruiter::KeyPool.next_key
  end

  test "returns nil without consented or credentials keys" do
    assert_nil Recruiter::KeyPool.next_key
  end
end
