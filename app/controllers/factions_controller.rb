class FactionsController < ApplicationController
  include FactionAccess

  before_action :require_faction_member, only: [ :show ]

  def index
    if Current.user.faction.present?
      redirect_to faction_path(Current.user.faction)
    else
      redirect_to root_path, alert: "You are not a member of any faction."
    end
  end

  def show
    unless @faction.track_stats
      @tracking_disabled = true
    end
  end
end
