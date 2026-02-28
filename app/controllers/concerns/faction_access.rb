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

  def require_setup_completed
    find_faction
    return if performed?

    unless @faction.setup_completed?
      redirect_to setup_faction_path(@faction)
    end
  end

  def require_faction_leadership
    find_faction
    return if performed?

    return if Current.user.admin?
    return if @faction.leadership.include?(Current.user)

    redirect_to faction_path(@faction), notice: "You don't have access to the Leadership dashboard. Ask your faction leader for access."
  end

  def find_faction
    torn_id = params[:faction_torn_id] || params[:torn_id]
    @faction = Faction.find_by!(torn_id: torn_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Faction not found."
  end
end
