require "test_helper"

class MatchChannelTest < ActionCable::Channel::TestCase
  test "anyone with the link can watch a match" do
    match = Match.create!

    subscribe id: match.id

    assert subscription.confirmed?
    assert_has_stream "match:#{match.id}"
  end

  test "unknown or malformed ids are rejected" do
    subscribe id: SecureRandom.uuid
    assert subscription.rejected?

    subscribe id: "not-a-uuid"
    assert subscription.rejected?
  end
end
