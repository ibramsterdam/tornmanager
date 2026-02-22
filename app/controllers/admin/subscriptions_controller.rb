module Admin
  class SubscriptionsController < ApplicationController
    before_action :require_admin

    def index
      @active_subscribers = User.active_subscribers.order(subscription_expires_at: :desc)
      @recent_payments = XanaxPayment.includes(:sender, :recipient).recent.limit(50)
    end

    def grant
      torn_id = params[:torn_id].to_i
      weeks = params[:weeks].to_i

      if torn_id <= 0 || weeks <= 0
        return redirect_to admin_subscriptions_path, alert: "Invalid Torn ID or weeks."
      end

      user = User.find_by(torn_id: torn_id)
      unless user
        return redirect_to admin_subscriptions_path, alert: "User with Torn ID #{torn_id} not found."
      end

      user.extend_subscription!(weeks)
      redirect_to admin_subscriptions_path, notice: "Granted #{weeks} week(s) to #{user.name} [#{user.torn_id}]."
    rescue => e
      redirect_to admin_subscriptions_path, alert: "Failed: #{e.message}"
    end

    def update_days
      user = User.find(params[:id])
      days = params[:days].to_i

      if days >= 0
        user.update!(subscription_expires_at: days.days.from_now)
        render json: { success: true, new_expires_at: user.subscription_expires_at.strftime("%Y-%m-%d %H:%M"), days: days }
      else
        render json: { success: false, error: "Days must be a positive number" }, status: :unprocessable_entity
      end
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
end
