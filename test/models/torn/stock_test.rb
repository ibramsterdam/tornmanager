require "test_helper"

class Torn::StockTest < ActiveSupport::TestCase
  # Fixtures: sym (torn_id: 16, price: 691.52, req: 500_000, freq: 7, dividend_value: 4_200_194)
  #           prn (torn_id: 18, price: 612.06, req: 1_000_000, freq: 7, dividend_value: 4_018_251)

  setup do
    @sym = torn_stocks(:sym)
    @prn = torn_stocks(:prn)
  end

  # -- block_cost --

  test "block_cost doubles with each increment" do
    inc1 = @sym.block_cost(1)
    inc2 = @sym.block_cost(2)
    inc3 = @sym.block_cost(3)

    assert_in_delta inc1 * 2, inc2, 0.01
    assert_in_delta inc2 * 2, inc3, 0.01
  end

  test "block_cost for increment 1 equals price times requirement" do
    expected = @sym.current_price * @sym.dividend_requirement
    assert_in_delta expected, @sym.block_cost(1), 0.01
  end

  # -- days_to_break_even_with_item --

  test "days_to_break_even returns infinity when dividend value is 0" do
    assert @sym.days_to_break_even_with_item(0, 1).infinite?
  end

  test "days_to_break_even increases with higher increments" do
    days_inc1 = @sym.days_to_break_even_with_item(@sym.dividend_value, 1)
    days_inc2 = @sym.days_to_break_even_with_item(@sym.dividend_value, 2)

    assert days_inc2 > days_inc1, "Higher increment should take longer to break even"
  end

  test "days_to_break_even returns positive integer for valid inputs" do
    days = @sym.days_to_break_even_with_item(@sym.dividend_value, 1)

    assert days > 0
    assert_equal days, days.to_i
  end

  # -- annual_roi --

  test "annual_roi returns percentage for valid inputs" do
    roi = @sym.annual_roi(1)

    assert roi > 0
    assert_kind_of Numeric, roi
  end

  test "annual_roi returns 0.0 when dividend value is 0" do
    @sym.dividend_value = 0
    assert_equal 0.0, @sym.annual_roi(1)
  end

  test "annual_roi halves with each increment" do
    roi1 = @sym.annual_roi(1)
    roi2 = @sym.annual_roi(2)

    assert_in_delta roi1 / 2, roi2, 0.01
  end

  test "annual_roi calculation is correct" do
    # SYM: price 691.52, req 500_000, freq 7, dividend_value 4_200_194
    # Block cost inc1 = 691.52 * 500_000 = 345_760_000
    # Annual dividends = 4_200_194 * (365 / 7) = 219_010_137.14...
    # ROI = 219_010_137.14 / 345_760_000 * 100 = 63.34%
    expected = (4_200_194.0 * (365.0 / 7) / (691.52 * 500_000) * 100).round(2)
    assert_equal expected, @sym.annual_roi(1)
  end

  # -- owns_increment? --

  test "owns_increment returns true when shares meet requirement" do
    assert @sym.owns_increment?(1, 500_000)
    assert @sym.owns_increment?(1, 600_000)
  end

  test "owns_increment returns false when shares below requirement" do
    assert_not @sym.owns_increment?(1, 499_999)
  end

  test "owns_increment doubles requirement per increment" do
    assert @sym.owns_increment?(2, 1_000_000)
    assert_not @sym.owns_increment?(2, 999_999)

    assert @sym.owns_increment?(3, 2_000_000)
    assert_not @sym.owns_increment?(3, 1_999_999)
  end

  # -- money_rows --

  test "money_rows returns 4 increments per money-making stock" do
    rows = Torn::Stock.money_rows([])

    stock_names = rows.map { |r| r[:stock_name] }.uniq
    stock_names.each do |name|
      increments = rows.select { |r| r[:stock_name] == name }.map { |r| r[:increment] }
      assert_equal [ 1, 2, 3, 4 ], increments.sort
    end
  end

  test "money_rows marks owned stocks correctly" do
    owned = [
      TornApi::User::Stocks::UserStock.new(
        stock_id: 16,
        total_shares: 1_500_000,
        dividend: nil,
        transactions: []
      )
    ]

    rows = Torn::Stock.money_rows(owned)
    sym_rows = rows.select { |r| r[:stock_name].include?("SYM") }

    # 1_500_000 shares: owns increment 1 (500k) and 2 (1M), not 3 (2M)
    assert sym_rows.find { |r| r[:increment] == 1 }[:owned]
    assert sym_rows.find { |r| r[:increment] == 2 }[:owned]
    assert_not sym_rows.find { |r| r[:increment] == 3 }[:owned]
  end

  test "money_rows marks all as not owned when no stocks provided" do
    rows = Torn::Stock.money_rows([])
    assert rows.all? { |r| r[:owned] == false }
  end
end
