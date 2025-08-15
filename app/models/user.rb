# app/models/user.rb: User model with Devise, custom role, and associations (free open-source ActiveRecord).
class User < ApplicationRecord
  # Include default Devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :clients, dependent: :destroy  # Allows user.clients, destroys associated clients on delete (free).

  # Custom role attribute
  validates :role, presence: true
end