Rails.application.routes.draw do
  mount Sidekiq::JobMonitor::Engine => "/sidekiq_job_monitor"
end
