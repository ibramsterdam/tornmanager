class UserApiCallsController < ApplicationController
  def index
    @api_calls = Current.user.api_calls.recent.limit(100)
    @peak_today = ApiCall.peak_rate_for(Current.user, scope: :today)
    @peak_all_time = ApiCall.peak_rate_for(Current.user, scope: :all)
  end
end
