module Kubeclient
  # caches results for multiple consumers to share and keeps them updated with a watch
  class Informer
    def initialize(client, resource_name, reconcile_timeout: 15 * 60, logger: nil)
      @client = client
      @resource_name = resource_name
      @reconcile_timeout = reconcile_timeout
      @logger = logger
      @cache = nil
      @started = nil
      @watching = []
    end

    def list
      @cache.values
    end

    def watch(&block)
      with_watching(&block)
    end

    # not implicit so users know they have to `stop`
    def start_worker
      @worker = Thread.new do
        loop do
          fill_cache
          watch_to_update_cache
        rescue StandardError => e
          # need to keep retrying since we work in the background
          @logger&.error("ignoring error during background work #{e}")
        ensure
          sleep(1) # do not overwhelm the api-server if we are somehow broken
        end
      end
      sleep(0.01) until @cache
    end

    def stop_worker
      @worker&.kill # TODO: be nicer ?
    end

    private

    def with_watching
      queue = Queue.new
      @watching << queue
      loop do
        x = queue.pop
        yield(x)
      end
    ensure
      @watching.delete(queue)
    end

    def cache_key(resource)
      resource.dig(:metadata, :uid)
    end

    def fill_cache
      reply = @client.get_entities(nil, @resource_name, raw: true, resource_version: '0')
      @cache = reply[:items].each_with_object({}) do |item, h|
        h[cache_key(item)] = item
      end
      @started = reply.dig(:metadata, :resourceVersion)
    end

    def watch_to_update_cache
      watcher = @client.watch_entities(@resource_name, watch: true, resource_version: @started)
      stop_reason = 'disconnect'

      # stop watcher without using timeout
      Thread.new do
        sleep(@reconcile_timeout)
        stop_reason = 'reconcile'
        watcher.finish
      end

      watcher.each do |notice|
        case notice[:type]
        when 'ADDED', 'MODIFIED' then @cache[cache_key(notice[:object])] = notice[:object]
        when 'DELETED' then @cache.delete(cache_key(notice[:object]))
        when 'ERROR'
          stop_reason = 'error'
          break
        else
          @logger&.error("Unsupported event type #{notice[:type]}")
        end
        @watching.each { |q| q << notice }
      end
      @logger&.info("watch restarted: #{stop_reason}")
    end
  end
end
