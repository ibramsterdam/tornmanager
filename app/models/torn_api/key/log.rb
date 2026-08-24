module TornApi
  module Key
    class Log < TornApi::Base
      LogEntry = Data.define(
        :timestamp,
        :type,
        :selections,
        :id,
        :ip,
        :comment
      )

      LogData = Data.define(
        :log,
        :_metadata
      )

      def fetch
        all_entries = []

        [ 0, 100, 200 ].each do |offset|
          data = get("v2/key/log", { limit: 100, offset: offset })

          raise TornApi::InvalidKeyError if data["error"]

          batch_entries = data["log"].map do |entry|
            LogEntry.new(
              timestamp: entry["timestamp"],
              type: entry["type"],
              selections: entry["selections"],
              id: entry["id"],
              ip: entry["ip"],
              comment: entry["comment"]
            )
          end

          all_entries.concat(batch_entries)

          break if batch_entries.size < 100
        end

        LogData.new(
          log: all_entries,
          _metadata: nil
        )
      end
    end
  end
end
