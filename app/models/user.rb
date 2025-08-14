# app/models/user.rb: User model with Devise and custom role (free open-source ActiveRecord).
class User < ApplicationRecord
  # Include default Devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Custom role attribute
  validates :role, presence: true
end