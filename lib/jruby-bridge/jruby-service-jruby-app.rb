#!/usr/bin/env jruby

raise ScriptError.new("JRuby is required") unless RUBY_PLATFORM =~ /java/

require 'java'
require 'jruby-service'

module JRubyBridge

=begin rdoc
JRuby code for managing a JRubyBridge service. This can be subclassed for use
in a specific JRuby application to be invoked by JRubyBridge::Service.
=end
  class Service

    # Number of clients connected to Service
    attr_reader :usage_count

    def initialize
      @usage_count = 0
    end

    # sure, this could probably use a mutex
    def inc_usage; @usage_count += 1; end
    def dec_usage; @usage_count -= 1; end
    def stop_if_unused; DRb.stop_service if (usage_count <= 0); end

    def self.drb_start(port)
      port ||= default_port

      DRb.start_service "druby://localhost:#{port.to_i}", self.new
      puts "jruby service started (#{Process.pid}). Connect to #{DRb.uri}"
     
      cls = self
      trap('HUP') { DRb.stop_service; cls.drb_start(port) }
      trap('INT') { puts 'Stopping jruby service'; DRb.stop_service }

      DRb.thread.join
    end

  end
end

# ----------------------------------------------------------------------
# main() : must invoke the above-defined class
JRubyBridge::Service.drb_start ARGV.first if __FILE__ == $0
