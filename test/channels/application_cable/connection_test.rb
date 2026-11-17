require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "guests can connect anonymously" do
    connect

    assert_nil connection.current_user
  end

  test "a signed-in player is identified from the session cookie" do
    session = users(:one).sessions.create!
    cookies.signed[:session_id] = session.id

    connect

    assert_equal users(:one), connection.current_user
  end
end
