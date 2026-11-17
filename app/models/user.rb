class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :delete_all

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
