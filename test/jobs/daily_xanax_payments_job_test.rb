require "test_helper"

class DailyXanaxPaymentsJobTest < ActiveJob::TestCase
  setup do
    @bram = users(:bram) # recipient (torn_id: 2728237)
    @bert = users(:bert) # existing sender

    @log_entry = TornApi::User::Log::LogEntry.new(
      id: "xanax_log_999",
      timestamp: 1708000000,
      sender_torn_id: @bert.torn_id,
      xanax_quantity: 3
    )
  end

  test "enqueues to the admin queue" do
    assert_equal "admin", Daily::XanaxPaymentsJob.new.queue_name
  end

  test "processes new xanax payment from existing user" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Log.any_instance.stubs(:fetch_xanax_payments).returns([ @log_entry ])

    assert_difference "XanaxPayment.count", 1 do
      Daily::XanaxPaymentsJob.perform_now
    end

    payment = XanaxPayment.last
    assert_equal @bram.id, payment.recipient_id
    assert_equal @bert.id, payment.sender_id
    assert_equal 3, payment.xanax_amount
    assert_equal 3, payment.weeks_granted
  end

  test "extends sender subscription" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Log.any_instance.stubs(:fetch_xanax_payments).returns([ @log_entry ])

    Daily::XanaxPaymentsJob.perform_now

    @bert.reload
    assert @bert.subscribed?, "Sender should have an active subscription after payment"
  end

  test "skips already-processed payments" do
    XanaxPayment.create!(
      recipient: @bram,
      sender: @bert,
      log_id: "xanax_log_999",
      xanax_amount: 3,
      weeks_granted: 3,
      processed_at: Time.at(1708000000)
    )

    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Log.any_instance.stubs(:fetch_xanax_payments).returns([ @log_entry ])

    assert_no_difference "XanaxPayment.count" do
      Daily::XanaxPaymentsJob.perform_now
    end
  end

  test "creates user record for unknown sender" do
    unknown_entry = TornApi::User::Log::LogEntry.new(
      id: "xanax_log_new",
      timestamp: 1708000000,
      sender_torn_id: 7777777,
      xanax_quantity: 1
    )

    profile = TornApi::User::Basic::BasicData.new(
      id: 7777777, name: "NewSender", level: 30, gender: "Male", status: "Okay"
    )

    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Log.any_instance.stubs(:fetch_xanax_payments).returns([ unknown_entry ])
    TornApi::User::Basic.any_instance.stubs(:fetch).returns(profile)

    assert_difference "User.count", 1 do
      Daily::XanaxPaymentsJob.perform_now
    end

    new_user = User.find_by(torn_id: 7777777)
    assert_equal "NewSender", new_user.name
    assert_nil new_user.api_key
  end

  test "creates minimal user when profile fetch fails" do
    unknown_entry = TornApi::User::Log::LogEntry.new(
      id: "xanax_log_fallback",
      timestamp: 1708000000,
      sender_torn_id: 8888888,
      xanax_quantity: 2
    )

    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::Log.any_instance.stubs(:fetch_xanax_payments).returns([ unknown_entry ])
    TornApi::User::Basic.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Not found")

    assert_difference "User.count", 1 do
      Daily::XanaxPaymentsJob.perform_now
    end

    fallback_user = User.find_by(torn_id: 8888888)
    assert_equal "User 8888888", fallback_user.name
    assert_equal 1, fallback_user.level
  end
end
