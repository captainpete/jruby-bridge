# jruby-bridge

`jruby-bridge` lets you create objects within MRI Ruby that have all their execution performed in a JRuby context.
To do this it uses a JRuby DRb service process. Objects passed by reference to method calls are transparently marshalled and executed within the JRuby service, and the results are passed back. Procs are executed in the context they're defined in.

This can be used to add commercial jdbc database support and other JRuby accessible tech to MRI-based projects without having to change much.

Based on, and forked from https://github.com/mkfs/jruby-bridge
"See http://entrenchant.blogspot.com/2012/07/drb-jruby-bridge.html for full discussion."

## Installation

Add this line to your application's Gemfile:

    gem 'jruby-bridge'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jruby-bridge

Pat a kitten.

## Usage by Example

```ruby
require 'jruby-bridge'

# Make sure JRuby has the right classes loaded
JRubyBridge::Service.remote_require 'kittens', 'puppies'

# Start the JRuby service process
JRubyBridge::Service.with_service do

  # Now, every new SomeClass lives remotely
  SomeClass.send :include, JRubyBridge::ObjectProxy

  # Make a remote object
  remote_object = SomeClass.new 'some', 'args'

  # executes in the JRuby process
  new_object = remote_object.do_stuff

  # also in the JRuby process (pass by ref)
  new_object.do_more_stuff

  # lambdas are executed in this process
  new_object.each { |thing| process thing }

end # Stop the JRuby service process
```

```ruby
# You can also control the service manually
JRubyBridge::Service.start
JRubyBridge::Service.stop
```

## TODO

1. Ahh, some tests?
2. Convince the Enterprise to stop using commercial databases
3. Lazy-launching of the service process
4. Hearbeat signal with auto-shutdown of service process
5. Proxy signals to the service

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
