class Factions::Leadership::SubscriptionsController < Factions::Leadership::BaseController
  def create
    faction_weeks = params[:weeks].to_i

    if faction_weeks <= 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "Please enter a valid number of weeks."
    end

    personal_cost = faction_weeks * faction_week_cost
    available = Current.user.subscription_weeks_remaining

    unless available >= personal_cost
      return redirect_to faction_leadership_settings_path(@faction),
        alert: "You need #{personal_cost} personal weeks but only have #{available}."
    end

    ActiveRecord::Base.transaction do
      Current.user.deduct_subscription!(personal_cost)

      if @faction.subscription
        @faction.subscription.extend!(faction_weeks)
      else
        @faction.create_subscription!(expires_at: Time.current + faction_weeks.weeks)
      end

      FactionSubscriptionGrant.create!(
        torn_faction_id: @faction.torn_id,
        faction: @faction,
        faction_name: @faction.name,
        weeks_granted: faction_weeks,
        granted_by: Current.user,
        granted_at: Time.current
      )
    end

    redirect_to faction_leadership_settings_path(@faction),
      notice: "Extended faction subscription by #{faction_weeks} week(s) (#{personal_cost} personal weeks used)."
  rescue => e
    Rails.logger.error("Extend faction subscription failed for user #{Current.user.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_settings_path(@faction), alert: "Failed to extend subscription: #{e.message}"
  end

  private

  def faction_week_cost
    (@faction.users.active.count / 10.0).ceil.clamp(1, 100)
  end
  helper_method :faction_week_cost
end
