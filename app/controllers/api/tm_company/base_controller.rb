module Api
  module TmCompany
    class BaseController < Api::BaseController
      before_action :require_company_access

      private

      def require_company_access
        return if @user.company_access?

        if @user.company_access_disabled?
          render json: { error: "TM Company access has been turned off for your account." }, status: :forbidden
        elsif @user.company_api_key.blank? || !@user.company_director?
          render json: { error: "Please sign in again with a Limited key from a company director.", reauth: true }, status: :unauthorized
        else
          render json: { error: "An active subscription is required.", subscription_required: true }, status: :forbidden
        end
      end
    end
  end
end
