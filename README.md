# Spork JRuby Support via RedBridge
This is a fork of the [spork](https://github.com/timcharper/spork) project that provides JRuby support through [RedBridge](https://github.com/jruby/jruby/wiki/RedBridge).

## Why?
Spork 0.9.0.rc supports JRuby through the magazine run strategy that runs separate processes for each of the workers. Each of these processes must run through the `Spork.prefork` before they can accept work. 

Unfortunately, there is no interlocking between the server and the workers. If the server attempts to hand off work to a worker before it has completed the execution of `Spork.prefork`, it is dropped. It's up to you to make sure you wait long enough before running the next test suite.

This behavior makes RubyMine's Spork integration really unhappy and, in my experience at least, requires RubyMine to be restarted once a work item has been dropped in order to make it happy with Spork again.

So, I set out to fix this as my project for the July 2011 LinkedIn Hackday.

## What's different?
This fork provides a new run strategy based on RedBridge to be used with Spork is running under JRuby. This strategy uses RedBridge to run worker JRuby VM instances within the same JVM. The worker processes still must run `Spork.prefork`, but interlocks make sure that the master and the workers stay in sync.

Because the workers are running within the same JVM as the Spork server, this approach should consume fewer resources than magazine strategy. The workers should also come online faster.

## How do I use it?

Change the spork gem specification in your Gemfile to:

    gem 'spork', :git => ':git => 'https://github.com/gregspurrier/spork'

If you need help with spork itself, refer to the official [README](https://github.com/timcharper/spork#readme). The instructions there should all be applicable to this fork.
