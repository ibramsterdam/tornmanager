module Api
  class RecruiterStatusController < BaseController
    before_action :require_active_subscription
    rate_limit to: 60, within: 1.minute

    MAX_COMPANIES = 30

    def show
      company_ids = Array(params[:company_ids]).map(&:to_i).reject(&:zero?).uniq.first(MAX_COMPANIES)

      statuses = {}
      pending = []
      company_ids.each do |company_id|
        cached = Rails.cache.read(Recruiter::CompanyStatusJob.cache_key(company_id))
        if cached
          statuses[company_id] = cached
        else
          pending << company_id
          enqueue_refresh(company_id)
        end
      end

      render json: { statuses: statuses, pending: pending }
    end

    private

    def enqueue_refresh(company_id)
      return unless Rails.cache.write("recruiter:status:enqueued:#{company_id}", true, unless_exist: true, expires_in: 1.minute)

      Recruiter::CompanyStatusJob.perform_later(company_id)
    end
  end
end
