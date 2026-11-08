module Admin
  class TmCompanyController < ApplicationController
    before_action :require_admin

    JOBS = {
      "capture_all" => ::TmCompany::CaptureAllJob,
      "backfill_snapshots" => ::TmCompany::BackfillSnapshotsJob
    }.freeze

    def show
      @users = User.joins(:company_api_key).includes(:company_api_key, :subscription).order(:name)
      @last_captures = CompanyDay.where(user_id: @users.map(&:id)).group(:user_id).maximum(:captured_at)
      @snapshot_days = CompanySnapshot.distinct.count(:date)
      @first_snapshot = CompanySnapshot.minimum(:date)
    end

    def run
      klass = JOBS[params[:job]]
      return redirect_to admin_tm_company_path, alert: "Unknown job." unless klass

      klass.perform_later
      redirect_to admin_tm_company_path, notice: "#{klass.name} enqueued."
    end

    def toggle_access
      user = User.find(params[:id])
      user.update!(company_access_disabled: !user.company_access_disabled?)
      state = user.company_access_disabled? ? "turned off" : "turned on"
      redirect_to admin_tm_company_path, notice: "TM Company access #{state} for #{user.name}."
    end
  end
end
