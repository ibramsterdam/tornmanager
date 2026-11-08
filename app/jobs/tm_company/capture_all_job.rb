module TmCompany
  class CaptureAllJob < ApplicationJob
    queue_as :default

    def perform
      User.joins(:company_api_key).where(company_director: true).find_each do |user|
        CaptureJob.perform_later(user.id) if user.company_access?
      end
    end
  end
end
