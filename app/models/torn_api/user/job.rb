module TornApi
  module User
    class Job < Base
      JobData = Data.define(:type, :company_id, :company_type_id, :company_name, :rating, :position) do
        def director?
          type == "company" && position == "Director"
        end
      end

      def fetch
        job = get("v2/user/job")["job"] || {}

        JobData.new(
          type: job["type"],
          company_id: job["id"],
          company_type_id: job["type_id"],
          company_name: job["name"],
          rating: job["rating"],
          position: job["position"]
        )
      end
    end
  end
end
