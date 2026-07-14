require "test_helper"

# HTTP 5xx responses from Torn (the 02:00 "HTTP 504" errors) are transient and
# must be retried at the client level like timeouts already are. When retries
# are exhausted, the failure must surface as TornApi::TransientError so the
# job layer can back off and retry later. Torn's own "try again" error codes
# (15, 17) get the same treatment.
class TornApi::BaseRetryTest < ActiveSupport::TestCase
  setup do
    @base = TornApi::Base.new("FACTION_KEY_123")
    @base.stubs(:sleep)
  end

  test "retries an HTTP 5xx response and succeeds" do
    bad = stub(code: "504", body: "gateway timeout")
    good = stub(code: "200", body: { "members" => [] }.to_json)
    @base.stubs(:perform_request).returns(bad).then.returns(good)

    result = @base.get("v2/faction/99999/members")

    assert_equal [], result["members"]
  end

  test "raises TransientError after exhausting 5xx retries" do
    bad = stub(code: "504", body: "gateway timeout")
    @base.stubs(:perform_request).returns(bad)

    assert_raises(TornApi::TransientError) do
      @base.get("v2/faction/99999/members")
    end
  end

  test "does not retry 4xx responses" do
    @base.expects(:perform_request).once.returns(stub(code: "403", body: "forbidden"))

    assert_raises(TornApi::ApiError) do
      @base.get("v2/faction/99999/members")
    end
  end

  test "torn 'temporary error' code 15 raises TransientError" do
    assert_raises(TornApi::TransientError) do
      @base.send(:handle_api_error, { "code" => 15, "error" => "Temporary error" })
    end
  end

  test "torn 'backend error' code 17 raises TransientError" do
    assert_raises(TornApi::TransientError) do
      @base.send(:handle_api_error, { "code" => 17, "error" => "Backend error occurred" })
    end
  end

  test "TransientError is still an ApiError for existing rescues" do
    assert TornApi::TransientError < TornApi::ApiError
  end

  test "rate limit code 5 still raises RateLimitError" do
    assert_raises(TornApi::RateLimitError) do
      @base.send(:handle_api_error, { "code" => 5, "error" => "Too many requests" })
    end
  end
end
