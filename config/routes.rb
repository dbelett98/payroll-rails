# config/routes.rb: Fixed routes for Step O completion
Rails.application.routes.draw do
  devise_for :users
  
  resources :employees, only: [:show, :new, :create, :edit, :update, :destroy] do
    collection do
      patch :bulk_update
      get :export_csv
      get :import_form
      post :import_preview
      post :import_employees
      post :compare_duplicate
    end
  end
  
  resources :clients, only: [:index, :new, :create, :edit, :update, :destroy]
  
  # ===== FIXED: PayrollRuns Routes =====
  resources :payroll_runs do
    member do
      patch :submit_for_review
      patch :approve
      patch :mark_as_processed    # FIXED: Changed from :process to :mark_as_processed
      patch :void
      patch :return_to_draft
    end
  end
  
  get '/dashboard', to: 'dashboards#show'
  root 'dashboards#show'
end