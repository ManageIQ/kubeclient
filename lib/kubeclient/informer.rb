module Kubeclient
  # caches results for multiple consumers to share and keeps them updated with a watch
  class Informer
    def initialize(client, resource_name, options: {}, reconcile_timeout: 15 * 60, logger: nil)
      @client = client
      @resource_name = resource_name
      @reconcile_timeout = reconcile_timeout
      @logger = logger
      @cache = nil
      @started = nil
      @stopped = false
      @watching = []
      @options = options
    end

    def list
      @cache.values
    end

    def watch(&block)
      with_watching(&block)
    end

    # not implicit so users know they have to `stop`
    def start_worker
      @stopped = false
      @worker = Thread.new do
        loop do
          begin
            fill_cache
            watch_to_update_cache
          rescue StandardError => e
            # need to keep retrying since we work in the background
            @logger&.error("ignoring error during background work #{e}")
          ensure
            sleep(1) # do not overwhelm the api-server if we are somehow broken
          end
          break if @stopped
        end
      end
      sleep(0.01) until @cache || @stopped
    end

    def stop_worker
      @stopped = true
      [@waiter, @worker].compact.each do |thread|
        begin
          thread.run # cancel sleep so either the loop sleep or the timeout sleep are interrupted
        rescue ThreadError
          # thread was already dead
        end
        thread.join
      end
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
      get_options = @options.merge(raw: true, resource_version: '0')
      reply = @client.get_entities(nil, @resource_name, get_options)
      @cache = reply[:items].each_with_object({}) do |item, h|
        h[cache_key(item)] = item
      end
      @started = reply.dig(:metadata, :resourceVersion)
    end

    def watch_to_update_cache
      watch_options = @options.merge(watch: true, resource_version: @started)
      @watcher = @client.watch_entities(@resource_name, watch_options)
      stop_reason = 'disconnect'

      # stop watcher without using timeout
      @waiter = Thread.new do
        sleep(@reconcile_timeout)
        stop_reason = 'reconcile'
        @watcher.finish
      end

      @watcher.each do |notice|
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

      # wake the waiter unless it's dead so it does not hang around
      begin
        Thread.pass # make sure we get into the sleep state of the waiter
        @waiter.run
      rescue ThreadError # rubocop:disable Lint/SuppressedException
      end
      @waiter.join
    end
  end
end
