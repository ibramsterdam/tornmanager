class HomeController < ApplicationController
  allow_unauthenticated_access
  def index
    if authenticated?
      if Current.user.faction&.track_stats
        redirect_to faction_path(Current.user.faction)
      else
        redirect_to stocks_path
      end
    end
  end
end
