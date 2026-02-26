class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    return unless authenticated?

    faction = Current.user.faction

    if faction
      redirect_to faction_path(faction)
    else
      redirect_to stocks_path
    end
  end
end
