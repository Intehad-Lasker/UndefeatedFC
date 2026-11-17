module Api
  module V1
    # POST /api/v1/passwords emails a reset link. The link opens the server-
    # rendered reset page from Rails' authentication generator, which shares the
    # session cookie with the React app, so no second reset UI is needed.
    class PasswordsController < BaseController
      rate_limit to: 5, within: 10.minutes, only: :create,
        store: Rails.configuration.x.rate_limit_store || Rails.cache,
        with: -> { render_error :too_many_requests, "rate_limited", "Too many reset requests. Try again in a few minutes." }

      def create
        if (user = User.find_by(email_address: params.require(:email_address).to_s.strip.downcase))
          PasswordsMailer.reset(user).deliver_later
        end

        # The same answer either way, so the form can't be used to discover accounts.
        render json: { message: "If that address has an account, a reset link is on its way." }, status: :accepted
      end
    end
  end
end
