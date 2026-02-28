class Factions::Leadership::SubscriptionsController < Factions::Leadership::BaseController

  def create
    total_weeks = params[:total_weeks].to_i
    members = @faction.users.active
    member_count = members.count

    if total_weeks <= 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "Please enter a valid number of weeks to share."
    end

    if member_count == 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "No faction members found."
    end

    if total_weeks % member_count != 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "#{total_weeks} weeks cannot be split evenly across #{member_count} members. Try a multiple of #{member_count}."
    end

    weeks_per_member = total_weeks / member_count

    if Current.user.subscription_weeks_remaining < total_weeks
      return redirect_to faction_leadership_settings_path(@faction), alert: "You only have #{Current.user.subscription_weeks_remaining} weeks remaining. Cannot share #{total_weeks} weeks."
    end

    ActiveRecord::Base.transaction do
      Current.user.deduct_subscription!(total_weeks)

      grant = FactionSubscriptionGrant.create!(
        torn_faction_id: @faction.torn_id,
        faction: @faction,
        faction_name: @faction.name,
        weeks_granted: total_weeks,
        granted_by: Current.user,
        granted_at: Time.current
      )

      members.each do |member|
        SubscriptionGrant.create!(
          faction_subscription_grant: grant,
          user: member
        )
        member.extend_subscription!(weeks_per_member)
      end
    end

    redirect_to faction_leadership_settings_path(@faction), notice: "Shared #{total_weeks} weeks across #{member_count} members (#{weeks_per_member} weeks each)."
  rescue => e
    Rails.logger.error("Share subscription failed for user #{Current.user.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_settings_path(@faction), alert: "Failed to share subscription: #{e.message}"
  end
end
