module Sidekiq
  module JobMonitor
    class Engine < ::Rails::Engine
      isolate_namespace Sidekiq::JobMonitor
    end
  end
end
