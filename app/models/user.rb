class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 10

  has_secure_password
  has_many :sessions, dependent: :delete_all

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name, with: ->(name) { name.strip }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { in: 3..20 },
    format: { with: /\A[A-Za-z0-9_]+\z/, message: "can only use letters, numbers and underscores" },
    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
end
