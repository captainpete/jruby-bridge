#!/usr/bin/env jruby

raise ScriptError.new("JRuby is required") unless RUBY_PLATFORM =~ /java/

require 'java'
require 'service'

JRubyBridge::Service.drb_start ARGV.first if __FILE__ == $0
