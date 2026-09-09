class EliminationDashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    return render :login unless cia_admin?

    load_status
  end

  def start
    return redirect_to elimination_dashboard_path unless cia_admin?

    EliminationSetting.current.start_polling!
    redirect_to elimination_dashboard_path, notice: "Polling started."
  end

  def stop
    return redirect_to elimination_dashboard_path unless cia_admin?

    EliminationSetting.current.stop_polling!
    redirect_to elimination_dashboard_path, notice: "Polling stopped."
  end

  def toggle
    return redirect_to elimination_dashboard_path unless cia_admin?

    entry = EliminationSetting::NOTIFICATIONS.find { |notification| notification[:key] == params[:key] }
    return redirect_to elimination_dashboard_path, alert: "Unknown notification." unless entry

    setting = EliminationSetting.current
    setting.toggle!("notify_#{entry[:key]}")
    state = setting.public_send("notify_#{entry[:key]}?") ? "on" : "off"
    redirect_to elimination_dashboard_path, notice: "#{entry[:label]} notifications #{state}."
  end

  def test
    return redirect_to elimination_dashboard_path unless cia_admin?

    kind = params[:kind]
    unless Elimination::Demo::KINDS.include?(kind)
      return redirect_to elimination_dashboard_path, alert: "Unknown test message."
    end

    Elimination::Demo.new(EliminationSetting.current).send!(kind)
    redirect_to elimination_dashboard_path, notice: "Sent #{kind.humanize.downcase} test message."
  end

  def trigger
    return redirect_to elimination_dashboard_path unless cia_admin?

    kind = params[:kind]
    unless Elimination::LiveTrigger::KINDS.include?(kind)
      return redirect_to elimination_dashboard_path, alert: "No live trigger for that message."
    end

    case Elimination::LiveTrigger.new(EliminationSetting.current).send!(kind)
    when :sent
      redirect_to elimination_dashboard_path, notice: "Sent live #{kind} message."
    when :first_place
      redirect_to elimination_dashboard_path, alert: "We are 1st, there is no countdown to show."
    else
      redirect_to elimination_dashboard_path, alert: "Our team was not found in the live data."
    end
  rescue TornApi::ApiError, TornApi::InvalidKeyError => e
    redirect_to elimination_dashboard_path, alert: "Torn API error: #{e.message}"
  end

  def login
    if correct_password?(params[:password])
      session[:cia_admin] = true
      redirect_to elimination_dashboard_path
    else
      @wrong_password = true
      render :login, status: :unauthorized
    end
  end

  def logout
    session.delete(:cia_admin)
    redirect_to elimination_dashboard_path
  end

  private

  def load_status
    @setting = EliminationSetting.current
    @bot_token_present = Rails.application.credentials.dig(:cia_bot, :bot_token).present?
  end

  def cia_admin?
    session[:cia_admin] == true
  end

  def correct_password?(attempt)
    password = Rails.application.credentials.dig(:cia_bot, :admin_dashboard_password)
    password.present? && ActiveSupport::SecurityUtils.secure_compare(attempt.to_s, password)
  end
end
