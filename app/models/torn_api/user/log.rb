module TornApi
  module User
    class Log < Base
      ENDPOINT = "v2/user/log".freeze
      XANAX_ITEM_ID = 206

      LogEntry = Data.define(
        :id,
        :timestamp,
        :sender_torn_id,
        :xanax_quantity
      )

      def fetch_xanax_payments(limit: 100)
        response = get(ENDPOINT, { log: 4103, limit: limit })
        response["log"].present? ? parse_logs(response["log"]) : []
      end

      private

      def parse_logs(logs)
        logs.filter_map do |log|
          next unless contains_xanax?(log)

          LogEntry.new(
            id: log["id"],
            timestamp: log["timestamp"],
            sender_torn_id: log["data"]["sender"],
            xanax_quantity: extract_xanax_quantity(log["data"]["items"])
          )
        end
      end

      def contains_xanax?(log)
        return false unless log["data"]&.[]("items")
        items = log["data"]["items"]

        case items
        when Array
          items.any? { |item| item.is_a?(Hash) && item["id"] == XANAX_ITEM_ID }
        when Hash
          items.key?(XANAX_ITEM_ID.to_s)
        else
          false
        end
      end

      def extract_xanax_quantity(items)
        case items
        when Array
          xanax_item = items.find { |item| item.is_a?(Hash) && item["id"] == XANAX_ITEM_ID }
          xanax_item&.[]("qty") || 0
        when Hash
          items[XANAX_ITEM_ID.to_s].to_i
        else
          0
        end
      end
    end
  end
end
