module Recruiter
  class KeyPool
    def self.next_key
      ApiKey.where(recruiter_fetch_allowed: true).order("RANDOM()").pick(:key) ||
        Rails.application.credentials.dig(:recruiter, :api_key)
    end
  end
end
