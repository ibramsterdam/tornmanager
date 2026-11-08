module TornApi
  module Torn
    class Companies < Base
      ENDPOINT = "v2/torn/companies".freeze

      def fetch
        companies = get(ENDPOINT, { comment: "tmcompany" })["companies"]
        raise ApiError, "No company types returned" if companies.blank?

        companies.is_a?(Hash) ? companies.values : companies
      end
    end
  end
end
