class UserscriptController < ApplicationController
  skip_forgery_protection only: :download

  def index
    @latest  = ScriptVersion.latest
    @versions = ScriptVersion.ordered
  end

  def download
    latest = ScriptVersion.latest

    if latest&.script_content.present?
      send_data latest.script_content,
        filename: "tornmanager.user.js",
        type: "text/javascript",
        disposition: "inline"
    else
      redirect_to userscript_path, alert: "No script available for download."
    end
  end
end
