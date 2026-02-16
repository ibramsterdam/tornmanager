module Admin
  class SubscriptionsController < ApplicationController
    before_action :require_admin

    def index
      @active_subscribers = User.active_subscribers.order(subscription_expires_at: :desc)
      @recent_payments = XanaxPayment.includes(:sender, :recipient).recent.limit(50)
      @recent_faction_grants = FactionSubscriptionGrant.includes(:granted_by).recent.limit(20)
    end

    def faction_grant
    end

    def create_faction_grant
      Rails.logger.info("Creating faction grant with params: faction_id=#{params[:faction_id]}, weeks=#{params[:weeks]}")
      Rails.logger.info("Valid params? #{valid_params?}")

      return redirect_with_error("Invalid faction ID or weeks.") unless valid_params?

      grant_faction_subscription
    rescue TornApi::InvalidKeyError => e
      Rails.logger.error("Invalid API key error: #{e.message}")
      Appsignal.increment_counter("subscription.faction_grant_failed", 1, { reason: "invalid_key" })
      redirect_with_error("Invalid API key.")
    rescue TornApi::ApiError => e
      Rails.logger.error("Torn API error: #{e.class} - #{e.message}")
      Appsignal.increment_counter("subscription.faction_grant_failed", 1, { reason: "api_error" })
      redirect_with_error("Torn API error: #{e.message}")
    rescue => e
      Rails.logger.error("Faction grant error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      Appsignal.increment_counter("subscription.faction_grant_failed", 1, { reason: "unexpected_error" })
      Appsignal.send_error(e)
      redirect_with_error("An error occurred: #{e.message}")
    end

    def update_days
      user = User.find(params[:id])
      days = params[:days].to_i

      if days >= 0
        user.update!(subscription_expires_at: days.days.from_now)
        Appsignal.increment_counter("subscription.days_updated", 1)
        render json: { success: true, new_expires_at: user.subscription_expires_at.strftime("%Y-%m-%d %H:%M"), days: days }
      else
        render json: { success: false, error: "Days must be a positive number" }, status: :unprocessable_entity
      end
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    private

    def valid_params?
      faction_id.positive? && weeks.positive?
    end

    def grant_faction_subscription
      faction_info = fetch_faction_info
      members = fetch_faction_members

      ActiveRecord::Base.transaction do
        grant = create_grant_record(faction_info["name"], members.count)
        members.each { |member| grant_to_member(grant, member) }
      end

      # Track faction grant
      Appsignal.increment_counter("subscription.faction_grant", 1)
      Appsignal.increment_counter("subscription.weeks_granted", weeks * members.count, { type: "faction_grant" })
      Appsignal.increment_counter("subscription.users_granted", members.count)

      redirect_to admin_subscriptions_path, notice: "Successfully granted #{weeks} week(s) to #{members.count} members of #{faction_info['name']}."
    end

    def fetch_faction_info
      TornApi::Faction::Basic.new(OwnerCredentials.api_key, faction_id).fetch
    end

    def fetch_faction_members
      TornApi::Faction::Members.new(OwnerCredentials.api_key, faction_id).fetch
    end

    def create_grant_record(faction_name, member_count)
      FactionSubscriptionGrant.create!(
        torn_faction_id: faction_id,
        faction_name: faction_name,
        weeks_granted: weeks,
        granted_by: Current.user,
        granted_at: Time.current
      )
    end

    def grant_to_member(grant, member)
      user = find_or_create_user(member)

      SubscriptionGrant.create!(
        faction_subscription_grant: grant,
        user: user
      )

      user.extend_subscription!(weeks)
    end

    def find_or_create_user(member)
      User.find_by(torn_id: member.id) || create_user_from_member(member)
    end

    def create_user_from_member(member)
      User.create!(
        torn_id: member.id,
        name: member.name,
        level: member.level,
        api_key: nil
      )
    end

    def redirect_with_error(message)
      redirect_to faction_grant_admin_subscriptions_path, alert: message
    end

    def faction_id
      @faction_id ||= params[:faction_id].to_i
    end

    def weeks
      @weeks ||= params[:weeks].to_i
    end
  end
end
