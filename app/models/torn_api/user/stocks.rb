module TornApi
  module User
    class Stocks < Base
      UserStock = Data.define(:stock_id, :total_shares, :dividend, :transactions)
      Dividend = Data.define(:ready, :increment, :progress, :frequency)
      Transaction = Data.define(:shares, :bought_price, :time_bought)
      ENDPOINT = "v2/user/stocks".freeze

      def fetch
        response = get(ENDPOINT, striptags: false)
        if response["stocks"].present?
          parse_user_stocks(response["stocks"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      private

      def parse_user_stocks(stock_data)
        stock_data.map do |stock_id, stock_details|
          UserStock.new(
            stock_id: stock_id.to_i,
            total_shares: stock_details["total_shares"],
            dividend: parse_dividend_info(stock_details["dividend"]),
            transactions: parse_transactions(stock_details["transactions"])
          )
        end
      end

      def parse_dividend_info(dividend_data)
        return nil unless dividend_data

        Dividend.new(
          ready: dividend_data["ready"],
          increment: dividend_data["increment"],
          progress: dividend_data["progress"],
          frequency: dividend_data["frequency"]
        )
      end

      def parse_transactions(transactions_data)
        return [] unless transactions_data

        transactions_data.map do |_, transaction_details|
          Transaction.new(
            shares: transaction_details["shares"],
            bought_price: transaction_details["bought_price"],
            time_bought: Time.at(transaction_details["time_bought"])
          )
        end
      end
    end
  end
end
