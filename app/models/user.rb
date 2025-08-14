# app/models/user.rb: User model with Devise and custom role, using password_digest (free open-source ActiveRecord).
class User < ApplicationRecord
  # Include default Devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Use existing password_digest instead of encrypted_password
  attr_reader :password
  attr_accessor :password_confirmation

  def password=(new_password)
    @password = new_password
    self.password_digest = BCrypt::Password.create(new_password) if new_password.present?
  end

  def valid_password?(password)
    BCrypt::Password.new(password_digest) == password
  end

  # Custom role attribute
  validates :role, presence: true
end