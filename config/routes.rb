Sidekiq::JobMonitor::Engine.routes.draw do
  resources :job_progress, only: [:show] do
    member do
      get 'cancel'
    end
  end
end
