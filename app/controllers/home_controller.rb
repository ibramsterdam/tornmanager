class HomeController < ApplicationController
  allow_unauthenticated_access
  def index
    if authenticated?
      faction = Current.user.faction
      if faction&.track_stats && can_access_faction?(faction)
        redirect_to faction_path(faction)
      else
        redirect_to stocks_path
      end
    end
  end

  private

  def can_access_faction?(faction)
    Current.user.admin? || faction.faction_whitelists.exists?(user: Current.user)
  end
end
