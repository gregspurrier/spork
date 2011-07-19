class Spork::RunStrategy::RedBridge::Master < Spork::RunStrategy
  def initialize(test_framework)
    super
    STDERR.puts 'Using JRuby RedBridge'
    @workers = []
    @next_worker_id = 1
    2.times { add_worker }
  end

  def preload
    # Workers share nothing with the master, so there is no point
    # in doing a preload in the master. Each worker will do their
    # own.
    true
  end

  def run(argv, error_stream, output_stream)
    # Delegate to the first worker
    worker = @workers.shift
    result = worker.run(argv, error_stream, output_stream)

    # Add a new worker to replace the one we just used
    add_worker

    result
  end

  def cleanup
    STDERR.puts "#cleanup"
    raise NotImplementedError
  end

  def running?
    STDERR.puts "#running?"
    false
  end

  def assert_ready!
    # This strategy does not require executing the prefork block
    # in the master, so it is always ready.
    true
  end

  def abort
    STDERR.puts "#abort"
    raise NotImplementedError
  end

private

  # Add a new worker to the pool
  def add_worker
    worker = Spork::RunStrategy::RedBridge::Worker.new(@next_worker_id, test_framework.short_name)
    @next_worker_id += 1
    worker.preload
    @workers << worker
  end
end
