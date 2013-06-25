# jruby_bridge

`jruby_bridge` proxies chunks of ruby code through to JRuby DRB Server and fetches the results.

This is useful for situations like having to plug your freshly minted Ruby app into some godawful legacy enterprise database, or other scenarios laced with java (we nearly called this barge_pole).

Based on, and forked from https://github.com/mkfs/jruby-bridge
"See http://entrenchant.blogspot.com/2012/07/drb-jruby-bridge.html for full discussion."

## Installation

Add this line to your application's Gemfile:

    gem 'jruby_bridge'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jruby_bridge

Then pat a kitten :tiger:

## Usage by Example

```ruby
require 'jruby_bridge'

# Make sure JRuby has the right classes loaded
JRubyBridge::Service.remote_require 'kittens', 'puppies'

# Or, if you've got a Rails stack you want loaded, you could use the
# following code in an initializer to make sure JRuby has access to all
# your classes.
#
# # config/initializers/jruby_bridge.rb
# JRubyBridge::Service.remote_require File.dirname(__FILE__) + '/../environment'


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
4. Timeouts on the service process?

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
