module Admin
  class SubscriptionsController < ApplicationController
    before_action :require_admin

    def index
      @faction_subscriptions = Subscription.where(subscribable_type: "Faction")
        .includes(:subscribable)
        .order(expires_at: :desc)
      @individual_subscriptions = Subscription.where(subscribable_type: "User")
        .where("expires_at > ?", Time.current)
        .includes(:subscribable)
        .order(expires_at: :desc)
      @recent_payments = XanaxPayment.includes(:sender, :recipient).recent.limit(50)
    end

    def grant
      target_type = params[:target_type] || "User"
      torn_id = params[:torn_id].to_i
      weeks = params[:weeks].to_i

      if torn_id <= 0 || weeks <= 0
        return redirect_to admin_subscriptions_path, alert: "Invalid Torn ID or weeks."
      end

      if target_type == "Faction"
        faction = Faction.find_by(torn_id: torn_id)
        unless faction
          return redirect_to admin_subscriptions_path, alert: "Faction with Torn ID #{torn_id} not found."
        end

        if faction.subscription
          faction.subscription.extend!(weeks)
        else
          faction.create_subscription!(expires_at: Time.current + weeks.weeks)
        end
        redirect_to admin_subscriptions_path, notice: "Granted #{weeks} week(s) to faction #{faction.name} [#{faction.torn_id}]."
      else
        user = User.find_by(torn_id: torn_id)
        unless user
          return redirect_to admin_subscriptions_path, alert: "User with Torn ID #{torn_id} not found."
        end

        user.extend_subscription!(weeks)
        redirect_to admin_subscriptions_path, notice: "Granted #{weeks} week(s) to #{user.name} [#{user.torn_id}]."
      end
    rescue => e
      redirect_to admin_subscriptions_path, alert: "Failed: #{e.message}"
    end

    def update_days
      subscription = Subscription.find(params[:id])
      days = params[:days].to_i

      if days >= 0
        subscription.update!(expires_at: days.days.from_now)
        render json: { success: true, new_expires_at: subscription.expires_at.strftime("%Y-%m-%d %H:%M"), days: days }
      else
        render json: { success: false, error: "Days must be a positive number" }, status: :unprocessable_entity
      end
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
end
