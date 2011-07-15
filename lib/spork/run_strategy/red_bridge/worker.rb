import java.util.concurrent.Semaphore

class Spork::RunStrategy::RedBridge::Worker
  def initialize(container, worker_id, framework_name)
    @container = container
    @worker_id = worker_id
    @framework_name
    @worker_go = Semaphore.new(0)
    @master_go = Semaphore.new(0)
    @params = [nil, nil, nil].to_java
    @result_container = [nil].to_java
  end

  def preload
    @thread = Thread.new do
      @container.put("worker_go", @worker_go)
      @container.put("master_go", @master_go)
      @container.put("$worker_id", @worker_id)
      @container.put("framework_name", @framework_name)
      @container.put("params", @params)
      @container.put("result_container", @result_container)
      @container.runScriptlet <<-EOS
        require 'rubygems'
        require 'spork'

        $orig_stdout = STDOUT
        $orig_stderr = STDERR

        def worker_log(message)
          $orig_stdout.puts "[Worker " + $worker_id.to_s + '] ' + message
          $orig_stdout.flush
        end

        worker_log 'Initializing'
        framework = Spork::TestFramework.factory(STDOUT, STDERR, framework_name)
        framework.preload

        worker_log 'Ready'
        master_go.release

        # It's show time!
        worker_go.acquire
        worker_log 'Working'
        begin
          # RubyMine's TeamCityFormatter used STDOUT/STDERR rather than
          # $stdout/$stderr, so we have to reset them here. We can't
          # use STDERR.reopen because the stream we have is a DRb object.
          Object.instance_eval do
            remove_const 'STDERR'
            const_set 'STDERR', params[1]
            remove_const 'STDOUT'
            const_set 'STDOUT', params[1]
          end
          $stderr = STDERR
          $stdout = STDOUT

          load framework.helper_file
          Spork.exec_each_run
          result_container[0] = framework.run_tests(params[0], STDERR, STDOUT)
          Spork.exec_after_each_run
        rescue Exception => e
          $orig_stderr.puts e.message
          $orig_stderr.puts e.backtrace.join("\n")
          $orig_stderr.flush
          @result_container[0] = 1 # Failure
        ensure
          worker_log 'Shutting down'
          master_go.release
        end
      EOS
    end
  end

  def run(argv, error_stream, output_stream)
    # Wait for the worker to be ready
    @master_go.acquire

    # Give the worker its marching orders and wait for it to finish.
    @params[0] = argv
    @params[1] = error_stream.to_java
    @params[2] = output_stream.to_java
    @worker_go.release
    @master_go.acquire

    # Return the result as reported by the worker
    @result_container[0]
  end
end
