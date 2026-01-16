require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @mock_user_stocks = [
      TornApi::User::Stocks::UserStock.new(
        stock_id: 16,
        total_shares: 1_500_000,
        dividend: TornApi::User::Stocks::Dividend.new(ready: 0, increment: 2, progress: 5, frequency: 7),
        transactions: [
          TornApi::User::Stocks::Transaction.new(shares: 957_754, bought_price: 675.8, time_bought: Time.new(2025, 3, 23, 18, 26, 26, "+01:00")),
          TornApi::User::Stocks::Transaction.new(shares: 34_511, bought_price: 667.06, time_bought: Time.new(2024, 4, 23, 17, 29, 1, "+02:00")),
          TornApi::User::Stocks::Transaction.new(shares: 81_704, bought_price: 636.74, time_bought: Time.new(2023, 11, 30, 20, 3, 8, "+01:00")),
          TornApi::User::Stocks::Transaction.new(shares: 79_835, bought_price: 626.47, time_bought: Time.new(2023, 11, 22, 14, 36, 57, "+01:00")),
          TornApi::User::Stocks::Transaction.new(shares: 80_191, bought_price: 627.07, time_bought: Time.new(2023, 11, 16, 9, 15, 23, "+01:00")),
          TornApi::User::Stocks::Transaction.new(shares: 17_107, bought_price: 627.41, time_bought: Time.new(2023, 11, 12, 21, 30, 18, "+01:00")),
          TornApi::User::Stocks::Transaction.new(shares: 79_792, bought_price: 626.86, time_bought: Time.new(2023, 11, 5, 10, 8, 10, "+01:00")),
          TornApi::User::Stocks::Transaction.new(shares: 3_270, bought_price: 631.69, time_bought: Time.new(2023, 10, 28, 17, 21, 2, "+02:00")),
          TornApi::User::Stocks::Transaction.new(shares: 79_533, bought_price: 630.3, time_bought: Time.new(2023, 10, 19, 10, 22, 10, "+02:00")),
          TornApi::User::Stocks::Transaction.new(shares: 86_303, bought_price: 625.73, time_bought: Time.new(2023, 10, 10, 20, 37, 8, "+02:00"))
        ]
      )
    ]
  end

  test "index" do
    sign_in_as(@user)

    TornApi::User::Stocks.any_instance.stubs(:fetch).returns(@mock_user_stocks)
    get progress_index_path
  end
end
