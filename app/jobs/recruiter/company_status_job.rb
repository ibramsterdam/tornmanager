module Recruiter
  class CompanyStatusJob < TornApiJob
    queue_with_priority 0
    limits_concurrency to: 1, key: "recruiter-status", group: CONCURRENCY_GROUP

    CACHE_TTL = 5.minutes

    def self.cache_key(company_torn_id)
      "recruiter:status:#{company_torn_id}"
    end

    def perform(company_torn_id)
      api_key = KeyPool.next_key
      return Rails.logger.warn("Recruiter::CompanyStatusJob: no recruiter api key, skipping") unless api_key

      employees = TornApi::Company::Employees.new(api_key, company_torn_id).fetch
      payload = employees.map do |employee|
        {
          torn_id: employee.torn_id,
          status: employee.status,
          relative: employee.relative,
          last_action_at: employee.last_action_at,
          position: employee.position,
          days_in_company: employee.days_in_company
        }
      end

      Rails.cache.write(self.class.cache_key(company_torn_id), payload, expires_in: CACHE_TTL)
    end
  end
end
