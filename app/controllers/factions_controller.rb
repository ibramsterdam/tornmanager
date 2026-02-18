class FactionsController < ApplicationController
  before_action :set_faction, only: [ :show ]

  def index
    # Redirect to current user's faction
    if Current.user.faction.present?
      redirect_to faction_path(Current.user.faction)
    else
      redirect_to root_path, alert: "You are not a member of any faction."
    end
  end

  def show
    # Faction dashboard with cards linking to sub-pages
  end

  private

  def set_faction
    @faction = Faction.find_by!(torn_id: params[:torn_id])

    # Authorization: users can only view their own faction, admins can view any
    unless Current.user.admin? || Current.user.faction == @faction
      redirect_to root_path, alert: "You don't have access to this faction."
      return
    end

    unless @faction.track_stats
      @tracking_disabled = true
    end
  end
end
