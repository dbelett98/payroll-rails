# config/routes.rb: Defines routes (free open-source Rails routing).
Rails.application.routes.draw do
  devise_for :users
  get '/dashboard', to: 'dashboards#show'  # Dashboard route (free).
  root 'dashboards#show'  # Set dashboard as root after login (free).
end