module Sidekiq
  module JobMonitor
    class Middleware
      # Wrap Sidekiq default job execution with completion and failure handling
      # to make previous jobs tracking easy
      def call(worker, msg, queue)
        job = Sidekiq::JobMonitor::Job.new(msg)

        job.processing!

        begin
          yield
          job.complete!
        rescue
          job.failed!
          raise
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::JobMonitor::Middleware
  end
end
