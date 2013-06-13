#!/usr/bin/env ruby

require 'drb'

=begin rdoc
A Ruby class for launching a JRuby application in a child process, using
DRuby to communicate between them.
=end
module JRubyBridge

  class JRubyExecError < StandardError; end
  class DRbConnectionError < StandardError; end

=begin rdoc
A Ruby-managed JRuby application.
=end
  class Service
    # Path to JRuby application
    DAEMON = File.join(File.dirname(__FILE__), 'server.rb')
    # Port to listen on in JRuby
    DEFAULT_PORT = 44344
    # Time to allow JRuby to initialize, in 100-ms increments
    TIMEOUT = 300

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

      cls = self
      trap('HUP') { DRb.stop_service; cls.drb_start(port) }
      trap('INT') { puts 'Stopping jruby service'; DRb.stop_service }

      DRb.thread.join
    end

    # derived classes can override this method to change the daemon
    def self.daemon; DAEMON; end

    # derived classes can override this method to change the timeout
    def self.timeout; TIMEOUT; end

    # derived classes can override this method to change the port
    def self.default_port; DEFAULT_PORT; end

    def self.default_uri; "druby://localhost:#{default_port}"; end

    # Return command to launch JRuby interpreter
    def self.get_jruby
      # FIXME: this should detect RVM first and system second

      # 1. detect system JRuby
      jruby = `which jruby`
      return jruby.chomp if (! jruby.empty?)

      # 2. detect RVM-managed JRuby
      return nil if (`which rvm`).empty?
      jruby = `rvm list`.split("\n").select { |rb| rb.include? 'jruby' }.first
      return nil if (! jruby)

      "rvm #{jruby.strip.split(' ').first} do ruby "
    end

    # Replace current process with JRuby running JRubyBridge::Service
    def self.exec(port)
      jruby = get_jruby
      Kernel.exec "#{jruby} #{daemon} #{port || ''}" if jruby

      # Note: a raised exception goes nowhere: instead use exit status
      $stderr.puts "No JRUBY found!"
      return 1
    end

    def self.start
      return @pid if @pid
      cls = self
      @pid = Process.fork do
        exit(cls.exec cls.default_port)
      end
      # TODO : check child exit status and raise JRubyExecError
      Process.detach(@pid)

      connected = false
      timeout.times do
        begin
          DRb::DRbObject.new_with_uri(default_uri).to_s
          connected = true
          break
        rescue DRb::DRbConnError
          sleep 0.1
        end
      end
      raise DRbConnectionError.new("Could not connect to #{default_uri}") if \
            (! connected)
    end

    def self.stop
      service_send(:stop_if_unused)
    end

    # this will return a new DRuby connection
    def self.service_send(method, *args)
      begin
        obj = DRb::DRbObject.new_with_uri(default_uri)
        obj.send(method, *args)
        obj
      rescue DRb::DRbConnError => e
        # $stderr.puts e.backtrace.join("\n")
        raise DRbConnectionError.new(e.message)
      end
    end

    def self.connect
      service_send(:inc_usage)
    end

    def self.disconnect
      service_send(:dec_usage)
    end

  end
end
