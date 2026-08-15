class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :reject_banned_user

  private

  # Boot an already-signed-in user the moment their ban takes effect.
  def reject_banned_user
    return unless Current.user&.banned?

    message = Current.user.ban_message
    terminate_session
    redirect_to new_session_path, alert: message
  end
end
