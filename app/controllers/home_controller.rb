class HomeController < ApplicationController
  allow_unauthenticated_access
  def index
    redirect_to progress_index_path if authenticated?
  end
end
