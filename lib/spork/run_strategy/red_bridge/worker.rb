require 'jruby'
require 'java'

import org.jruby.embed.ScriptingContainer
import org.jruby.embed.LocalContextScope
import org.jruby.embed.PathType
import java.util.concurrent.Semaphore

class Spork::RunStrategy::RedBridge::Worker
  def initialize(worker_id, framework_name)
    @container = ScriptingContainer.new(LocalContextScope::SINGLETHREAD)
    @container.set_environment(ENV)
    @container.set_load_paths($LOAD_PATH)

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
    @thread.join

    result = @result_container[0]
  end
end
