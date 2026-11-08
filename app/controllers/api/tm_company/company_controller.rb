module Api
  module TmCompany
    class CompanyController < BaseController
      rate_limit to: 60, within: 1.minute

      REFRESH_AFTER = 15.minutes
      HISTORY_DAYS = (7..730)

      def overview
        day = latest_day
        return render json: { pending: true, queued: queue_capture } unless day

        render json: ::TmCompany::Report.new(day)
      end

      def history
        days = params.fetch(:days, 30).to_i.clamp(HISTORY_DAYS.min, HISTORY_DAYS.max)
        render json: ::TmCompany::History.new(@user.company_id, days: days)
      end

      def news
        entries = CompanyNewsEntry.where(company_torn_id: @user.company_id).order(occurred_at: :desc).limit(100)
        render json: { news: entries.map { |entry| { id: entry.news_id, text: entry.text, occurred_at: entry.occurred_at } } }
      end

      def refresh
        day = latest_day
        if day && day.date == Date.current && day.captured_at > REFRESH_AFTER.ago
          return render json: { queued: false, captured_at: day.captured_at }
        end

        render json: { queued: queue_capture, captured_at: day&.captured_at }
      end

      private

      def latest_day
        CompanyDay.for_company(@user.company_id).order(date: :desc).first
      end

      def queue_capture
        return false unless Rails.cache.write("tm_company:capture_queued:#{@user.id}", true, unless_exist: true, expires_in: REFRESH_AFTER)

        ::TmCompany::CaptureJob.perform_later(@user.id)
        true
      end
    end
  end
end
