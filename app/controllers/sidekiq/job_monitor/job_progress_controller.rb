module Sidekiq
  module JobMonitor
    class JobProgressController < ApplicationController
      before_action :load_job

      def show
        render json: data
      end

      def cancel
        @job.cancel
        load_job # Reload job to update state
        render json: data
      end

      private

      def load_job
        @job = Sidekiq::JobMonitor::Job.find(params[:id])
        # Fail and return 404 if no job was found
        head 404 unless @job
      end

      def data
        # The only intersting data from the job is its state,
        # arguments shouldn't be returned to the client
        { id: @job.attributes['jid'], state: @job.state }.tap do |data|
          # Allow the worker class to hook into data serialization by calling
          # the #monitoring_data instance method with the job arguments and
          # state as arguments
          if (monitoring_data = @job.monitoring_data)
            data.merge!(monitoring_data)
          end
        end
      end
    end
  end
end
