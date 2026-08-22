require "csv"

module TornApi
  module User
    class Snapshot < Base
      include CsvResponse

      ENDPOINT = "v2/user/snapshot".freeze
      Row = Data.define(
        :torn_id,
        :name,
        :level,
        :company_id,
        :director
      )

      def endpoint
        ENDPOINT
      end

      def fetch
        body = get(endpoint, { comment: "tmrecruiter" })
        raise ApiError, "No user snapshot returned: #{body}" unless body.is_a?(String)

        parse_employed(body)
      end

      private

      def parse_employed(csv)
        rows = []
        CSV.new(csv, headers: true).each do |row|
          company_id = row["company"].to_i
          next if company_id.zero?

          rows << Row.new(
            torn_id: row["id"].to_i,
            name: row["name"],
            level: row["level"].to_i,
            company_id: company_id,
            director: row["job"] == "Director"
          )
        end
        rows
      end
    end
  end
end
