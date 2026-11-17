module Api
  module V1
    # Parent of every JSON endpoint.
    #
    # - Errors always come back as { "error": { "code": ..., "message": ... } }.
    # - Each browser gets an anonymous player id in a signed, HTTP-only cookie;
    #   only that player can change the drafts they start.
    # - CSRF protection stays on. The current token is sent on every response in
    #   the X-CSRF-Token header, and the React app echoes it back on writes.
    class BaseController < ActionController::Base
      class Forbidden < StandardError; end

      PLAYER_COOKIE = :player_id

      # The same cookie-backed sessions as the HTML side (Rails' authentication
      # generator). Guests can play, so endpoints opt in to requiring a user.
      include Authentication
      allow_unauthenticated_access

      protect_from_forgery with: :exception

      before_action { request.format = :json }
      after_action :expose_csrf_token

      rescue_from ActiveRecord::RecordNotFound do
        render_error :not_found, "not_found", "That #{controller_name.singularize} does not exist."
      end
      rescue_from ActionController::ParameterMissing do |error|
        render_error :bad_request, "bad_request", error.message
      end
      rescue_from ActionController::InvalidAuthenticityToken do
        render_error :forbidden, "invalid_csrf_token", "Your session expired. Reload the page and try again."
      end
      rescue_from Forbidden do |error|
        render_error :forbidden, "forbidden", error.message
      end
      rescue_from Drafts::RuleViolation do |error|
        render_error :unprocessable_content, "rule_violation", error.message
      end
      rescue_from ActiveRecord::RecordInvalid do |error|
        render_error :unprocessable_content, "validation_failed", error.record.errors.full_messages.to_sentence,
          fields: error.record.errors.to_hash(true)
      end

      private

      def current_player_id
        @current_player_id ||= cookies.signed[PLAYER_COOKIE] || assign_player_id
      end

      def assign_player_id
        SecureRandom.uuid.tap do |id|
          cookies.signed.permanent[PLAYER_COOKIE] = { value: id, httponly: true, same_site: :lax }
        end
      end

      def current_user = (Current.user if authenticated?)

      # Called by require_authentication; JSON clients get a 401, not a redirect.
      def request_authentication
        render_error :unauthorized, "unauthorized", "Sign in to do that."
      end

      def render_error(status, code, message, **details)
        render json: { error: { code: code, message: message, **details } }, status: status
      end

      def expose_csrf_token
        response.set_header("X-CSRF-Token", form_authenticity_token)
      end
    end
  end
end
