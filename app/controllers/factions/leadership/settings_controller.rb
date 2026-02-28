class Factions::Leadership::SettingsController < Factions::Leadership::BaseController
  def show
    load_settings_data
  end
end
