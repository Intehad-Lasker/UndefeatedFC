module ApplicationCable
  # Anyone may connect: leaderboards are public. A signed-in player is
  # identified from the same session cookie the app uses, so channels that need
  # an account can check current_user and reject the subscription themselves.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_session_user
    end

    private
      def find_session_user
        Session.includes(:user).find_by(id: cookies.signed[:session_id])&.user if cookies.signed[:session_id]
      end
  end
end
