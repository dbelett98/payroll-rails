# config/routes.rb: Defines routes (free open-source Rails routing).
Rails.application.routes.draw do
  devise_for :users
  resources :employees, only: [:new, :create, :edit, :update, :destroy]  # Adds CRUD routes for existing Employee model (free).
  get '/dashboard', to: 'dashboards#show'  # Dashboard route (free).
  root 'dashboards#show'  # Set dashboard as root after login (free).
end