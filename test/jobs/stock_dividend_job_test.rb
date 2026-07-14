require "test_helper"

class StockDividendJobTest < ActiveJob::TestCase
  setup do
    @sym_stock = torn_stocks(:sym)
    @prn_stock = torn_stocks(:prn)
  end

  test "enqueues to the torn_api queue" do
    assert_equal "torn_api", Daily::StockDividendJob.new.queue_name
  end

  test "updates dividend values from API response" do
    fetched_sym = Torn::Stock.new(
      torn_id: 16, name: "Symbiotic Ltd.", acronym: "SYM",
      current_price: 700, dividend_frequency: 7, dividend_requirement: 500_000,
      dividend_description: "$5,000,000"
    )
    fetched_prn = Torn::Stock.new(
      torn_id: 18, name: "Performance Ribaldry", acronym: "PRN",
      current_price: 620, dividend_frequency: 7, dividend_requirement: 1_000_000,
      dividend_description: "1x Erotic DVD"
    )

    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::Torn::Stocks.any_instance.stubs(:fetch).returns([ fetched_sym, fetched_prn ])

    Daily::StockDividendJob.perform_now

    assert_equal 5_000_000, @sym_stock.reload.dividend_value
    # PRN has "1x" format — uses item market price from fixture (torn_id 366 = 4030490)
    assert_equal 4_030_490, @prn_stock.reload.dividend_value
  end

  test "calculates cash dividends from dollar amounts" do
    fetched = Torn::Stock.new(
      torn_id: 16, name: "Symbiotic Ltd.", acronym: "SYM",
      current_price: 700, dividend_frequency: 7, dividend_requirement: 500_000,
      dividend_description: "$1,234"
    )

    AdminCredentials.stubs(:api_key).returns("test_key")
    TornApi::Torn::Stocks.any_instance.stubs(:fetch).returns([ fetched ])

    Daily::StockDividendJob.perform_now

    assert_equal 1234, @sym_stock.reload.dividend_value
  end
end
