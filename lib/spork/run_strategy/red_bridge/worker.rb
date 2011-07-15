import java.util.concurrent.Semaphore
import org.jruby.embed.PathType

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
      @container.runScriptlet(PathType::ABSOLUTE, File.expand_path('worker_scriptlet.rb', File.dirname(__FILE__)))
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
