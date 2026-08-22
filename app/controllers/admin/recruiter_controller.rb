module Admin
  class RecruiterController < ApplicationController
    before_action :require_admin

    JOBS = {
      "sync_roster" => Recruiter::SyncRosterJob,
      "sweep_working_stats" => Recruiter::SweepWorkingStatsJob,
      "backfill_missing_stats" => Recruiter::BackfillMissingStatsJob
    }.freeze

    RECURRING_KEYS = {
      "sync_roster" => "recruiter_sync_roster",
      "sweep_working_stats" => "recruiter_sweep_working_stats",
      "backfill_missing_stats" => "recruiter_backfill_missing_stats"
    }.freeze

    SECTION_LOADERS = {
      "pipeline" => :load_pipeline,
      "jobs" => :load_jobs,
      "keys" => :load_keys,
      "ratings" => :load_ratings
    }.freeze

    def show
    end

    def section
      loader = SECTION_LOADERS[params[:name]]
      return head :not_found unless loader

      send(loader)
      render partial: "admin/recruiter/#{params[:name]}"
    end

    def run
      klass = JOBS[params[:job]]
      return redirect_to admin_recruiter_path, alert: "Unknown job." unless klass

      klass.perform_later
      redirect_to admin_recruiter_path, notice: "#{klass.name} enqueued."
    end

    private

    def load_pool
      @pool_keys = ApiKey.where(recruiter_fetch_allowed: true).includes(:user, :submitted_by).order(:created_at)
      @service_key_present = Rails.application.credentials.dig(:recruiter, :api_key).present?
    end

    def load_pipeline
      load_pool
      @companies_count = Company.count
      @roster_synced_at = Company.maximum(:synced_at)
      @employed_count = User.employed.count
      @with_stats_count = User.employed.with_working_stats.count
      @swept_at = User.maximum(:working_stats_at)
      @backfill_pending = SolidQueue::Job.where(class_name: "Recruiter::FetchPlayerHofJob", finished_at: nil).count
      @coverage_gap = User.employed
        .where(company_director: false, working_stats: nil)
        .where(company_id: Company.where(rating: Recruiter::BackfillMissingStatsJob::MIN_COMPANY_RATING..).select(:torn_id))
        .count
    end

    def load_jobs
      @jobs = JOBS.map do |slug, klass|
        last = SolidQueue::Job.where(class_name: klass.name).order(id: :desc).first
        {
          slug: slug,
          klass: klass,
          last: last,
          failed: last.present? && SolidQueue::FailedExecution.exists?(job_id: last.id),
          next_time: SolidQueue::RecurringTask.find_by(key: RECURRING_KEYS[slug])&.next_time
        }
      end
    end

    def load_keys
      load_pool
      @calls_today = ApiCall.where(api_key: @pool_keys.map(&:key), created_at: Time.current.all_day).group(:api_key).count
    end

    def load_ratings
      @companies_by_rating = Company.group(:rating).count
    end
  end
end
