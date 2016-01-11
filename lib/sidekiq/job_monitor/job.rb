module Sidekiq
  module JobMonitor
    class Job
      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes.as_json(only: %w(class jid args state))
      end

      def save
        Sidekiq.redis do |conn|
          conn.set(store_key, serialize)
          # Expire key in 1 hours to avoid garbage keys
          conn.expire(store_key, 3_600) if conn.ttl(store_key) == -1
        end
      end

      def store_key
        @store_key ||= self.class.store_key_for(attributes['jid'])
      end

      def serialize
        attributes.to_json
      end

      def state
        @state ||= attributes['state'] || 'pending'
      end

      # Add #processing!, #complete! and #failed! methods
      %w(processing complete failed).each do |key|
        define_method(:"#{ key }!") do
          self.state = key
          save
        end
      end

      def state=(value)
        @state = attributes['state'] = value
      end

      def as_json(*args)
        attributes.as_json(*args)
      end

      def worker
        attributes['class'].constantize
      end

      def monitoring_data
        worker_instance = worker.new

        if worker_instance.respond_to?(:monitoring_data)
          worker_instance.monitoring_data(*attributes['args'], state)
        end
      end

      class << self
        def find(jid)
          find_in_queues(jid) || find_in_previous(jid)
        end

        def store_key_for(jid)
          ['sidekiq-job_monitor', jid].join(':')
        end

        private

        def find_in_queues(jid)
          job = Sidekiq::Queue.new.find_job(jid)
          new(job.item) if job
        end

        def find_in_previous(jid)
          data = Sidekiq.redis do |conn|
            conn.get(store_key_for(jid))
          end

          new(JSON.parse(data)) if data
        end
      end
    end
  end
end
