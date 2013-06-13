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

Then pat a kitten :kitten:

## Usage by Example

```ruby
require 'jruby_bridge'

class TerrorAdapter # Yay java tech
  def exec(query, patches = {}, &block)
    # This is executed in JRuby
    results = JavaTechnologyQueryFactoryFactory.new(stuff).dance
    results.each &block
  end
end

def query_the_terror(keyword)
  # bridge your object of choice
  adapter = JRubyBridge.launch TerrorAdapter.new

  # Methods are executed in the remote JRuby VM
  adapter.exec(keyword, 'Tuttle' => 'Buttle') do |row|
    # Procs are executed in the local Ruby VM
    name = row[:name].gsub('Tuttle', 'Buttle')
    puts "Terrorist detected: #{name}" if terrorist? name
  end
ensure
  adapter.jruby_bridge.close
end

def terrorist?(name)
  [true, true, false].sample # FIXME 2001
end
```

## TODO

1. Ahh, some tests?
2. Convince the Enterprise to stop using commercial databases

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
