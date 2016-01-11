module Sidekiq
  module JobMonitor
    class JobProgressController < ApplicationController
      def show
        job = Sidekiq::JobMonitor::Job.find(params[:id])
        # Fail and return 404 if no job was found
        return head 404 unless job
        # The only intersting data from the job is its state,
        # arguments shouldn't be returned to the client
        data = { id: job.attributes['jid'], state: job.state }
        # Allow the worker class to hook into data serialization by calling
        # the #monitoring_data instance method with the job arguments and state
        # as arguments
        if (monitoring_data = job.monitoring_data)
          data.merge!(monitoring_data)
        end

        render json: data
      end
    end
  end
end
