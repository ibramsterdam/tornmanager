class Factions::Leadership::SpyReportsController < Factions::Leadership::BaseController
  def show
    load_spy_stats_data
    load_settings_data
  end
end
