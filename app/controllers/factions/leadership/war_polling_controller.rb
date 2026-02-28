class Factions::Leadership::WarPollingController < Factions::Leadership::BaseController
  def start
    war = @faction.current_war
    unless war
      redirect_to faction_leadership_path(@faction), alert: "No active ranked war to poll."
      return
    end

    @faction.start_war_polling!
    redirect_to faction_leadership_path(@faction), notice: "War polling started."
  end

  def stop
    @faction.stop_war_polling!
    redirect_to faction_leadership_path(@faction), notice: "War polling stopped."
  end
end
