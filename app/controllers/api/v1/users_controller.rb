module Api
  module V1
    # POST /api/v1/users signs a player up and signs them in.
    class UsersController < BaseController
      rate_limit to: 10, within: 1.hour, only: :create,
        store: Rails.configuration.x.rate_limit_store || Rails.cache,
        with: -> { render_error :too_many_requests, "rate_limited", "Too many sign-ups from here. Try again later." }

      def create
        @user = User.create!(params.expect(user: %i[email_address display_name password]))
        sign_in(@user)
        render "api/v1/sessions/show", status: :created
      end
    end
  end
end
