class Factions::WarPollingController < ApplicationController
  include FactionAccess

  before_action :require_faction_leader

  def start
    war = @faction.current_war
    unless war
      redirect_to faction_path(@faction), alert: "No active ranked war to poll."
      return
    end

    unless @faction.faction_setting&.torn_api_key?
      redirect_to setup_faction_leadership_path(@faction), alert: "Torn API key must be configured before starting war polling."
      return
    end

    @faction.start_war_polling!
    redirect_to faction_path(@faction), notice: "War polling started."
  end

  def stop
    @faction.stop_war_polling!
    redirect_to faction_leadership_path(@faction, anchor: "settings"), notice: "War polling stopped."
  end
end
