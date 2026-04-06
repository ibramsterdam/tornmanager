class Factions::Leadership::SubscriptionsController < Factions::Leadership::BaseController
  def create
    weeks = params[:weeks].to_i

    if weeks <= 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "Please enter a valid number of weeks."
    end

    unless Current.user.subscription_weeks_remaining >= weeks
      return redirect_to faction_leadership_settings_path(@faction),
        alert: "You only have #{Current.user.subscription_weeks_remaining} weeks remaining."
    end

    ActiveRecord::Base.transaction do
      Current.user.deduct_subscription!(weeks)

      if @faction.subscription
        @faction.subscription.extend!(weeks)
      else
        @faction.create_subscription!(expires_at: Time.current + weeks.weeks)
      end

      FactionSubscriptionGrant.create!(
        torn_faction_id: @faction.torn_id,
        faction: @faction,
        faction_name: @faction.name,
        weeks_granted: weeks,
        granted_by: Current.user,
        granted_at: Time.current
      )
    end

    redirect_to faction_leadership_settings_path(@faction),
      notice: "Extended faction subscription by #{weeks} week(s)."
  rescue => e
    Rails.logger.error("Extend faction subscription failed for user #{Current.user.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_settings_path(@faction), alert: "Failed to extend subscription: #{e.message}"
  end
end
