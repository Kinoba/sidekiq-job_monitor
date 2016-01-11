Sidekiq::JobMonitor::Engine.routes.draw do
  resources :job_progress, only: [:show]
end
