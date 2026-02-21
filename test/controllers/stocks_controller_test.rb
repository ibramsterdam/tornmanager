require "test_helper"

class StocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bert)
    @mock_user_stocks = [
      TornApi::User::Stocks::UserStock.new(
        stock_id: 16,
        total_shares: 1_500_000,
        dividend: TornApi::User::Stocks::Dividend.new(ready: 0, increment: 2, progress: 5, frequency: 7),
        transactions: [
          TornApi::User::Stocks::Transaction.new(shares: 1_500_000, bought_price: 675.8, time_bought: Time.new(2025, 3, 23))
        ]
      )
    ]
  end

  # -- Authentication --

  test "redirects to login when not authenticated" do
    get stocks_path
    assert_redirected_to new_session_path
  end

  test "redirects to login when user has no API key" do
    @user.update!(api_key: nil)
    sign_in_as(@user)
    get stocks_path
    assert_redirected_to new_session_path
    assert_match /Please sign in/, flash[:alert]
  end

  # -- Limited Access user sees owned column --

  test "limited access user sees stock table with owned column" do
    @user.update!(api_access_type: "Limited Access")
    sign_in_as(@user)
    TornApi::User::Stocks.any_instance.stubs(:fetch).returns(@mock_user_stocks)

    get stocks_path
    assert_response :success
    assert_select "h1", "Stocks"
    assert_select "th", text: "OWNED"
  end

  # -- Non-limited access user sees table without owned column --

  test "non-limited access user sees stock table without owned column" do
    @user.update!(api_access_type: "Minimal Access")
    sign_in_as(@user)

    get stocks_path
    assert_response :success
    assert_select "th", text: "OWNED", count: 0
    assert_select ".alert-info", /Limited Access Required/
  end

  # -- API error handling --

  test "invalid API key redirects to login" do
    @user.update!(api_access_type: "Limited Access")
    sign_in_as(@user)
    TornApi::User::Stocks.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid key")

    get stocks_path
    assert_redirected_to new_session_path
    assert_match /Invalid or expired API key/, flash[:alert]
  end

  test "API error redirects to root with message" do
    @user.update!(api_access_type: "Limited Access")
    sign_in_as(@user)
    TornApi::User::Stocks.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Rate limited")

    get stocks_path
    assert_redirected_to root_path
    assert_match /Could not fetch stock data/, flash[:alert]
  end

  # -- Table content --

  test "table rows are sorted by days to break even" do
    @user.update!(api_access_type: "Limited Access")
    sign_in_as(@user)
    TornApi::User::Stocks.any_instance.stubs(:fetch).returns(@mock_user_stocks)

    get stocks_path
    assert_response :success
    assert_select "table tbody tr"
  end
end
