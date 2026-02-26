class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    return unless authenticated?

    faction = Current.user.faction

    if faction
      redirect_to faction_path(faction)
    elsif session[:torn_faction_id].present?
      redirect_to faction_path(torn_id: session[:torn_faction_id])
    else
      redirect_to stocks_path
    end
  end
end
