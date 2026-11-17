require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build(**attributes)
    User.new(email_address: "new@example.com", display_name: "NewPlayer", password: "long enough password", **attributes)
  end

  test "downcases and strips email addresses" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "is valid with an email, display name and long password" do
    assert build.valid?
  end

  test "display names are unique regardless of case" do
    user = build(display_name: "firstplayer")

    assert_not user.valid?
    assert_includes user.errors[:display_name], "has already been taken"
  end

  test "database enforces case-insensitive display name uniqueness" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      User.insert!({ email_address: "x@example.com", display_name: "FIRSTPLAYER", password_digest: "x" })
    end
  end

  test "display names are 3 to 20 letters, numbers or underscores" do
    assert_not build(display_name: "ab").valid?
    assert_not build(display_name: "a" * 21).valid?
    assert_not build(display_name: "no spaces").valid?
    assert build(display_name: "  Spaced_OK  ").tap(&:validate).then { |u| u.display_name == "Spaced_OK" && u.valid? }
  end

  test "passwords need at least ten characters" do
    user = build(password: "short")

    assert_not user.valid?
    assert user.errors.key?(:password)
  end

  test "email addresses must look like email addresses" do
    assert_not build(email_address: "not-an-email").valid?
  end
end
