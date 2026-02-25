module FactionAccess
  extend ActiveSupport::Concern

  private

  def require_faction_member
    find_faction
    return if performed?

    unless Current.user.admin? || Current.user.faction == @faction
      redirect_to root_path, alert: "You don't have access to this faction."
    end
  end

  def require_faction_whitelisted
    find_faction
    return if performed?

    return if Current.user.admin?
    return if @faction.faction_whitelists.exists?(user: Current.user)

    redirect_to stocks_path, alert: "You don't have access to this faction's dashboard. Ask your faction leader for access."
  end

  def require_faction_leader
    find_faction
    return if performed?

    return if Current.user.admin?

    unless Current.user.faction == @faction
      redirect_to root_path, alert: "You don't have access to this faction."
      return
    end

    verify_leader_role
  end

  def find_faction
    torn_id = params[:faction_torn_id] || params[:torn_id]
    @faction = Faction.find_by!(torn_id: torn_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Faction not found."
  end

  def verify_leader_role
    members = TornApi::Faction::Members.new(Current.user.api_key, @faction.torn_id).fetch
    member = members.find { |m| m.id == Current.user.torn_id }

    unless member && %w[Leader Co-leader].include?(member.position)
      redirect_to faction_path(@faction), alert: "Only faction leaders can access this page."
    end
  rescue TornApi::ApiError => e
    Rails.logger.error("Faction leader check failed: #{e.class} - #{e.message}")
    redirect_to faction_path(@faction), alert: "Could not verify faction role. Please try again."
  end
end
