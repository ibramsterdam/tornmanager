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
        :employees_hired,
        :employees_capacity,
        :daily_income,
        :daily_customers,
        :weekly_income,
        :weekly_customers
      )

      def initialize(api_key, timestamp: nil, comment: "tmrecruiter")
        super(api_key)
        @timestamp = timestamp
        @comment = comment
      end

      def endpoint
        ENDPOINT
      end

      def fetch
        params = { comment: @comment }
        params[:timestamp] = @timestamp.to_i if @timestamp
        body = get(endpoint, params)
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
            employees_hired: row["employees_hired"].to_i,
            employees_capacity: row["employees_capacity"]&.to_i,
            daily_income: row["daily_income"]&.to_i,
            daily_customers: row["daily_customers"]&.to_i,
            weekly_income: row["weekly_income"]&.to_i,
            weekly_customers: row["weekly_customers"]&.to_i
          )
        end
      end
    end
  end
end
