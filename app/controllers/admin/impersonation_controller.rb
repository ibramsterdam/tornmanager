module Admin
  class ImpersonationController < ApplicationController
    before_action :require_admin

    def create
      user = User.find(params[:id])
      start_new_session_for(user)
      redirect_to root_path, notice: "Now impersonating #{user.name} [#{user.torn_id}]"
    end
  end
end
