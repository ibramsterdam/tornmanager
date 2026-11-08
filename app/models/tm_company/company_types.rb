module TmCompany
  module CompanyTypes
    CACHE_KEY = "tm_company:company_types".freeze

    def self.find(type_id)
      all[type_id.to_i]
    end

    def self.all
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.day) do
        api_key = AdminCredentials.api_key || Recruiter::KeyPool.next_key
        TornApi::Torn::Companies.new(api_key).fetch.index_by { |type| type["id"].to_i }
      end
    rescue TornApi::ApiError, TornApi::InvalidKeyError => e
      Rails.logger.warn("TmCompany::CompanyTypes: #{e.message}")
      {}
    end
  end
end
