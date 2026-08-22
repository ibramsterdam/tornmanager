require "test_helper"

class TornApi::User::HofTest < ActiveSupport::TestCase
  test "returns the working stats value" do
    service = TornApi::User::Hof.new("test_key", 1234567)
    service.expects(:get)
      .with("v2/user/1234567/hof", { comment: "tmrecruiter" })
      .returns({ "hof" => { "working_stats" => { "value" => 250000, "rank" => 1200 } } })

    assert_equal 250000, service.fetch
  end

  test "handles alternate working stats keys" do
    service = TornApi::User::Hof.new("test_key", 1234567)
    service.expects(:get).returns({ "hof" => { "workstats" => { "value" => 99 } } })

    assert_equal 99, service.fetch
  end

  test "returns nil when working stats are absent" do
    service = TornApi::User::Hof.new("test_key", 1234567)
    service.expects(:get).returns({ "hof" => { "attacks" => { "value" => 5 } } })

    assert_nil service.fetch
  end
end
