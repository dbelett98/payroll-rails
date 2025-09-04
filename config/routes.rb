# config/routes.rb: Enhanced routes for Step L features
Rails.application.routes.draw do
  devise_for :users
  resources :employees, only: [:show, :new, :create, :edit, :update, :destroy] do  # Added :show
    collection do
      patch :bulk_update
      get :export_csv
      get :import_form                    # Show import form
      post :import_employees              # Process import file
    end
  end
  resources :clients, only: [:index, :new, :create, :edit, :update, :destroy]
  get '/dashboard', to: 'dashboards#show'
  root 'dashboards#show'
end