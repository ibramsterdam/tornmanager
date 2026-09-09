class EliminationDashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    render :login unless cia_admin?
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

  def cia_admin?
    session[:cia_admin] == true
  end

  def correct_password?(attempt)
    password = Rails.application.credentials.dig(:cia_bot, :admin_dashboard_password)
    password.present? && ActiveSupport::SecurityUtils.secure_compare(attempt.to_s, password)
  end
end
