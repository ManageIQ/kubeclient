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
        until @stopped
          begin
            fill_cache
            stop_reason = watch_to_update_cache
            @logger&.info("watch restarted: #{stop_reason}")
          rescue StandardError => e
            # need to keep retrying since we work in the background
            @logger&.error("ignoring error during background work #{e}")
          ensure
            sleep(1) # do not overwhelm the api-server if we are somehow broken
          end
        end
      end
      sleep(0.01) until @cache || @stopped
    end

    def stop_worker
      @stopped = true # mark that any threads should be stopped if it is running
      pass_and_run(@worker) # skip the end loop sleep
      @worker.join
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
      watcher_with_timeout do |watcher|
        stop_reason = 'disconnect'

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

        stop_reason
      end
    end

    def watcher_with_timeout
      watch_options = @options.merge(watch: true, resource_version: @started)
      @watcher = @client.watch_entities(@resource_name, watch_options)
      timeout_deadline = Time.now + @reconcile_timeout
      watcher_finished = false

      finisher_thread = Thread.new do
        sleep(0.5) until @stopped || watcher_finished || Time.now > timeout_deadline
        # loop calling finish until the actual method has
        # exited, since watcher.each may be called after the
        # finish in this thread is called
        loop do
          @watcher.finish
          break if watcher_finished
          sleep(0.5)
        end
      end

      stop_reason = yield(@watcher)
      Time.now > timeout_deadline ? 'reconcile' : stop_reason # return the reason
    ensure
      watcher_finished = true
      pass_and_run(finisher_thread) # skip the sleep to evaluate exit condition
      finisher_thread.join
    end

    def pass_and_run(thread)
      Thread.pass
      thread.run
    rescue ThreadError
      # thread was already dead
    end
  end
end
