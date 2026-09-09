module Admin
  class EliminationsController < ApplicationController
    before_action :require_admin
    before_action :set_setting

    def show
      load_status
    end

    def update
      if @setting.update(setting_params)
        redirect_to admin_eliminations_path, notice: "Settings saved."
      else
        load_status
        render :show, status: :unprocessable_entity
      end
    end

    def start
      @setting.start_polling!
      redirect_to admin_eliminations_path, notice: "Polling started."
    end

    def stop
      @setting.stop_polling!
      redirect_to admin_eliminations_path, notice: "Polling stopped."
    end

    def test
      kind = params[:kind]
      unless Elimination::Demo::KINDS.include?(kind)
        return redirect_to admin_eliminations_path, alert: "Unknown test message."
      end

      Elimination::Demo.new(@setting).send!(kind)
      redirect_to admin_eliminations_path, notice: "Sent #{kind.humanize.downcase} test message."
    end

    private

    def set_setting
      @setting = EliminationSetting.current
    end

    def load_status
      @latest_snapshots = EliminationSnapshot.latest_batch.order(tickets: :desc)
      @snapshot_count = EliminationSnapshot.count
      @bot_token_present = Rails.application.credentials.dig(:cia_bot, :bot_token).present?
    end

    def setting_params
      params.require(:elimination_setting).permit(
        :team_name, :api_key, :alerts_channel_id,
        :poll_interval_seconds, :push_window_seconds,
        :push_ticket_threshold, :push_resolve_seconds, :countdown_bottom_ranks,
        :standings_interval_minutes, :life_ticks_from
      )
    end
  end
end
