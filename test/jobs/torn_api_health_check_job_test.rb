require "test_helper"

class TornApiHealthCheckJobTest < ActiveJob::TestCase
  setup do
    @endpoint = "v2/faction/9055/members"
    AdminCredentials.stubs(:api_key).returns("TEST_KEY_123")
    Rails.env.stubs(:production?).returns(true)
  end

  test "posts recovery when endpoint is healthy" do
    TornApi::Base.any_instance.stubs(:get).returns({})
    Discord::Notifier.expects(:send_to_channel).with(
      TornApiHealthCheckJob::DISCORD_CHANNEL_ID,
      has_entry(:embed, has_entry(:title, ":green_circle: Torn API Recovered"))
    )

    TornApiHealthCheckJob.perform_now(@endpoint)
  end

  test "clears degraded cache on recovery" do
    TornApi::Base.any_instance.stubs(:get).returns({})
    Discord::Notifier.stubs(:send_to_channel)

    Rails.cache.write("torn_degraded:v2/faction/{id}/members", true)
    TornApiHealthCheckJob.perform_now(@endpoint)

    assert_not Rails.cache.exist?("torn_degraded:v2/faction/{id}/members")
  end

  test "re-enqueues and notifies when endpoint still failing with 5xx" do
    TornApi::Base.any_instance.stubs(:get).raises(TornApi::ApiError, "Torn API request failed (HTTP 502)")
    Discord::Notifier.expects(:send_to_channel).with(
      TornApiHealthCheckJob::DISCORD_CHANNEL_ID,
      has_entry(:embed, has_entry(:title, ":yellow_circle: Torn API Still Degraded"))
    )

    assert_enqueued_with(job: TornApiHealthCheckJob, args: [ @endpoint ]) do
      TornApiHealthCheckJob.perform_now(@endpoint)
    end
  end

  test "does not re-enqueue for non-5xx api errors" do
    TornApi::Base.any_instance.stubs(:get).raises(TornApi::ApiError, "API error 2: Invalid key")
    Discord::Notifier.expects(:send_to_channel).never

    assert_no_enqueued_jobs(only: TornApiHealthCheckJob) do
      TornApiHealthCheckJob.perform_now(@endpoint)
    end
  end

  test "does nothing without admin api key" do
    AdminCredentials.stubs(:api_key).returns(nil)
    TornApi::Base.any_instance.expects(:get).never

    TornApiHealthCheckJob.perform_now(@endpoint)
  end

  test "sanitizes endpoint ids in messages" do
    TornApi::Base.any_instance.stubs(:get).returns({})
    Discord::Notifier.expects(:send_to_channel).with(
      anything,
      has_entry(:embed, has_entry(:description, includes("v2/faction/{id}/members")))
    )

    TornApiHealthCheckJob.perform_now(@endpoint)
  end
end
