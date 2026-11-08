module Api
  module TmCompany
    class KeysController < Api::BaseController
      def destroy
        @user.company_api_key&.destroy!
        head :no_content
      end
    end
  end
end
