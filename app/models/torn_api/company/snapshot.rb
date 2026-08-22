require "csv"

module TornApi
  module Company
    class Snapshot < Base
      include CsvResponse

      ENDPOINT = "v2/company/snapshot".freeze
      Row = Data.define(
        :torn_id,
        :name,
        :company_type_id,
        :rating,
        :employees_hired
      )

      def endpoint
        ENDPOINT
      end

      def fetch
        body = get(endpoint, { comment: "tmrecruiter" })
        raise ApiError, "No company snapshot returned: #{body}" unless body.is_a?(String)

        parse(body)
      end

      private

      def parse(csv)
        CSV.parse(csv, headers: true).map do |row|
          Row.new(
            torn_id: row["id"].to_i,
            name: row["name"],
            company_type_id: row["type"].to_i,
            rating: row["rating"].to_i,
            employees_hired: row["employees_hired"].to_i
          )
        end
      end
    end
  end
end
