require "test_helper"

class ApiCallTest < ActiveSupport::TestCase
  test "requires an endpoint" do
    call = users(:bram).api_calls.build(status: "success", api_key: "k")
    assert_not call.valid?
  end

  test "requires a status" do
    call = users(:bram).api_calls.build(endpoint: "/user", api_key: "k")
    assert_not call.valid?
  end

  test "recent returns newest first" do
    old  = users(:bram).api_calls.create!(endpoint: "/old", status: "success", api_key: "k", created_at: 2.hours.ago)
    fresh = users(:bram).api_calls.create!(endpoint: "/new", status: "success", api_key: "k", created_at: 1.second.from_now)

    assert_equal fresh, users(:bram).api_calls.recent.first
  end

  test "today excludes yesterday" do
    users(:bram).api_calls.create!(endpoint: "/y", status: "success", api_key: "k", created_at: 1.day.ago)
    today = users(:bram).api_calls.create!(endpoint: "/t", status: "success", api_key: "k")

    assert_includes users(:bram).api_calls.today, today
    assert_equal 1, users(:bram).api_calls.today.where(endpoint: ["/y", "/t"]).count
  end

  test "last 24 hours excludes older calls" do
    users(:bram).api_calls.create!(endpoint: "/old", status: "success", api_key: "k", created_at: 25.hours.ago)
    recent = users(:bram).api_calls.create!(endpoint: "/new", status: "success", api_key: "k", created_at: 1.hour.ago)

    results = users(:bram).api_calls.last_24_hours
    assert_includes results, recent
    assert_not results.where(endpoint: "/old").exists?
  end

  test "successful scope filters by success" do
    users(:bram).api_calls.create!(endpoint: "/ok", status: "success", api_key: "k")
    users(:bram).api_calls.create!(endpoint: "/fail", status: "error", api_key: "k")

    assert users(:bram).api_calls.successful.where(endpoint: "/ok").exists?
    assert_not users(:bram).api_calls.successful.where(endpoint: "/fail").exists?
  end

  test "failed scope filters by error" do
    users(:bram).api_calls.create!(endpoint: "/ok", status: "success", api_key: "k")
    users(:bram).api_calls.create!(endpoint: "/fail", status: "error", api_key: "k")

    assert users(:bram).api_calls.failed.where(endpoint: "/fail").exists?
    assert_not users(:bram).api_calls.failed.where(endpoint: "/ok").exists?
  end

  test "peak rate finds the busiest minute" do
    burst_time = 2.hours.ago.change(sec: 0)
    5.times { |i| users(:bram).api_calls.create!(endpoint: "/burst", status: "success", api_key: "k", created_at: burst_time + i.seconds) }

    quiet_time = 1.hour.ago.change(sec: 0)
    2.times { |i| users(:bram).api_calls.create!(endpoint: "/quiet", status: "success", api_key: "k", created_at: quiet_time + i.seconds) }

    result = ApiCall.peak_rate_for(users(:bram))
    assert_equal 5, result[:rate]
    assert_not_nil result[:minute_start]
  end

  test "peak rate today ignores yesterday" do
    yesterday = 1.day.ago.change(sec: 0)
    10.times { |i| users(:bram).api_calls.create!(endpoint: "/y", status: "success", api_key: "k", created_at: yesterday + i.seconds) }

    today = Time.current.change(sec: 0) - 30.minutes
    3.times { |i| users(:bram).api_calls.create!(endpoint: "/t", status: "success", api_key: "k", created_at: today + i.seconds) }

    assert_equal 3, ApiCall.peak_rate_for(users(:bram), scope: :today)[:rate]
  end

  test "peak rate is zero with no calls" do
    users(:bert).api_calls.destroy_all

    result = ApiCall.peak_rate_for(users(:bert))
    assert_equal 0, result[:rate]
    assert_nil result[:minute_start]
  end

  test "peak rate is scoped to the user" do
    burst_time = 1.hour.ago.change(sec: 0)
    3.times { |i| users(:bert).api_calls.create!(endpoint: "/u2", status: "success", api_key: "k", created_at: burst_time + i.seconds) }
    7.times { |i| users(:bram).api_calls.create!(endpoint: "/u1", status: "success", api_key: "k", created_at: burst_time + i.seconds) }

    assert_equal 3, ApiCall.peak_rate_for(users(:bert))[:rate]
  end

  test "broadcasts to ActionCable after create" do
    ApiRateMonitorChannel.expects(:broadcast_to).with(
      users(:bram),
      has_entries(endpoint: "/test", status: "success")
    )

    users(:bram).api_calls.create!(endpoint: "/test", status: "success", api_key: "k")
  end

  test "broadcast payload includes id, created_at, and response_time" do
    ApiRateMonitorChannel.expects(:broadcast_to).with(
      users(:bram),
      has_key(:id) & has_key(:created_at) & has_entries(response_time: 150)
    )

    users(:bram).api_calls.create!(endpoint: "/user", status: "success", api_key: "k", response_time: 150)
  end
end
