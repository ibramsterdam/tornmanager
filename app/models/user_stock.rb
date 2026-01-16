class UserStock
  Transaction = Data.define(:shares, :bought_price, :time_bought)
  DividendInfo = Data.define(:ready, :increment, :progress, :frequency)

  attr_reader :stock, :total_shares, :transactions, :dividend_info

  def initialize(stock:, total_shares:, transactions: {}, dividend_info: nil)
    @stock = stock
    @total_shares = total_shares
    @transactions = parse_transactions(transactions)
    @dividend_info = parse_dividend_info(dividend_info)
  end

  def dividend_blocks
    base = stock.base_increment
    blocks = 0
    remaining = total_shares

    while remaining >= base
      blocks += 1
      remaining -= base
      base *= 2
    end

    blocks
  end

  def days_remaining_for_dividend
    return nil unless dividend_info

    dividend_info.frequency - dividend_info.progress
  end

  def dividend_ready?
    dividend_info && dividend_info["ready"] == 1
  end

  def summary
    {
      "Stock" => stock.name,
      "Torn ID" => stock.torn_id,
      "Total Shares" => total_shares,
      "Dividend Blocks" => dividend_blocks,
      "Dividend Ready?" => dividend_ready?,
      "Days Remaining for Dividend" => days_remaining_for_dividend
    }
  end

  private

  def parse_transactions(transactions_hash)
    transactions_hash.map do |_, details|
      Transaction.new(
        shares: details["shares"],
        bought_price: details["bought_price"],
        time_bought: Time.at(details["time_bought"])
      )
    end
  end

  def parse_dividend_info(dividend_info_hash)
    return nil unless dividend_info_hash

    DividendInfo.new(
      ready: dividend_info_hash["ready"],
      increment: dividend_info_hash["increment"],
      progress: dividend_info_hash["progress"],
      frequency: dividend_info_hash["frequency"]
    )
  end
end
