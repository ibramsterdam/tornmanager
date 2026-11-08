module TmCompany
  class CaptureJob < TornApiJob
    queue_with_priority 10
    limits_concurrency to: 1, key: ->(user_id) { "tm_company_capture:#{user_id}" }, group: CONCURRENCY_GROUP

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user&.company_access?

      api_key = user.company_api_key.key
      job = TornApi::User::Job.new(api_key).fetch
      unless job.director?
        user.update!(company_director: false)
        return
      end

      user.update!(company_id: job.company_id) if user.company_id != job.company_id
      capture(user, TornApi::Company::Director.new(api_key), job.company_id)
      BackfillSnapshotsJob.perform_later if BackfillSnapshotsJob.needed?
    rescue TornApi::InvalidKeyError => e
      Rails.logger.warn("TmCompany::CaptureJob: key for user #{user_id} no longer works: #{e.message}")
    end

    private

    def capture(user, director, company_torn_id)
      day = CompanyDay.find_or_initialize_by(company_torn_id: company_torn_id, date: Date.current)
      day.update!(
        user: user,
        captured_at: Time.current,
        profile: director.profile,
        employees: director.employees,
        stock: optional { director.stock },
        detailed: optional { director.detailed }
      )

      since = CompanyNewsEntry.where(company_torn_id: company_torn_id).maximum(:occurred_at)
      CompanyNewsEntry.record!(company_torn_id, director.news(since: since))
    end

    def optional
      yield
    rescue TornApi::ApiError => e
      raise if e.is_a?(TornApi::RateLimitError) || e.is_a?(TornApi::TransientError)

      Rails.logger.warn("TmCompany::CaptureJob: skipped a selection: #{e.message}")
      nil
    end
  end
end
