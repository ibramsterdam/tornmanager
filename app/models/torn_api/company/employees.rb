module TornApi
  module Company
    class Employees < Base
      attr_reader :company_id

      Employee = Data.define(
        :torn_id,
        :status,
        :relative,
        :last_action_at,
        :position,
        :days_in_company
      )

      def initialize(api_key, company_id)
        super(api_key)
        @company_id = company_id
      end

      def endpoint
        "v2/company/#{company_id}/employees"
      end

      def fetch
        response = get(endpoint, { comment: "tmrecruiter" })
        parse(response["employees"] || [])
      end

      private

      def parse(collection)
        collection.map do |employee|
          action = employee["last_action"] || {}
          position = employee["position"]
          position = position["name"] if position.is_a?(Hash)

          Employee.new(
            torn_id: employee["id"],
            status: action["status"] || "Offline",
            relative: action["relative"] || "",
            last_action_at: action["timestamp"],
            position: position,
            days_in_company: employee["days_in_company"]
          )
        end
      end
    end
  end
end
