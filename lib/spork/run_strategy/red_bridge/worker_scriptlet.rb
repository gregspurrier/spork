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
    const_set 'STDOUT', params[2]
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
