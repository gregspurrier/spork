if RUBY_PLATFORM == 'java'
  require 'jruby'
  require 'java'

  module Spork::RunStrategy::RedBridge
  end

  require 'spork/run_strategy/red_bridge/master'
  require 'spork/run_strategy/red_bridge/worker'
end
