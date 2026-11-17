module Api
  module V1
    # Sign in and out from the React app. Uses the same database-backed session
    # cookie as the generated HTML login, so one sign-in works everywhere.
    class SessionsController < BaseController
      rate_limit to: 10, within: 3.minutes, only: :create,
        store: Rails.configuration.x.rate_limit_store || Rails.cache,
        with: -> { render_error :too_many_requests, "rate_limited", "Too many sign-in attempts. Try again in a few minutes." }

      # GET /api/v1/session: who is signed in, if anyone.
      def show
        @user = current_user
      end

      def create
        @user = User.authenticate_by(params.permit(:email_address, :password))
        if @user
          start_new_session_for(@user)
          render :show, status: :created
        else
          render_error :unauthorized, "invalid_credentials", "That email address and password don't match."
        end
      end

      def destroy
        terminate_session if authenticated?
        head :no_content
      end
    end
  end
end
