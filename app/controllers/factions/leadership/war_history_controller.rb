class Factions::Leadership::WarHistoryController < Factions::Leadership::BaseController
  def show
    load_wars_data
  end
end
