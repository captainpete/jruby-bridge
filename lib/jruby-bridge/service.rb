#!/usr/bin/env ruby

require 'drb'

=begin rdoc
A Ruby class for launching a JRuby application in a child process, using
DRuby to communicate between them.
=end
module JRubyBridge

=begin rdoc
A Ruby-managed JRuby application.
=end
  class Service
    # Path to JRuby application
    DAEMON = File.join(File.dirname(__FILE__), 'server.rb')
    # Port to listen on in JRuby
    PORT = 44344
    # Time to allow JRuby to initialize, in 100-ms increments
    TIMEOUT = 300

    # Objects created from within this instance
    # reside in the JRuby process
    def remote_proxied_new(klass, *args)
      klass.proxied_new *args
    end

    def self.remote_require(*args)
      @remote_requires = args
    end

    def self.remote_requires
      @remote_requires ||= []
    end

    def self.with_service(&block)
      start
      yield
    ensure
      stop
    end

    def self.start
      return @pid if @pid
      _self = self
      @pid = Process.fork do
        exit _self.exec(PORT)
      end
      # TODO : check child exit status and raise JRubyExecError
      Process.detach(@pid)

      connected = false
      TIMEOUT.times do
        begin
          DRb::DRbObject.new_with_uri(default_uri).to_s
          connected = true
          break
        rescue DRb::DRbConnError
          sleep 0.1
        end
      end
      unless connected
        raise "Could not connect to #{default_uri}"
      end
    end

    def self.stop
      new_drb_object.stop
    end

    def stop
      DRb.stop_service
    end

    # Replace current process with JRuby running JRubyBridge::Service
    def self.exec(port)
      unless jruby = get_jruby
        # Note: a raised exception goes nowhere: instead use exit status
        $stderr.puts "No JRuby found!"
        return 1
      end

      command = [
        jruby,
        remote_requires.map { |path| %Q(-r"#{path}") },
        "\"#{DAEMON}\"",
        port
      ].compact.join(' ')

      Kernel.exec command
    end

    # Called by the server script in JRuby context
    def self.drb_start(port)
      port ||= PORT

      DRb.start_service "druby://localhost:#{port.to_i}", self.new

      _self = self
      trap('HUP') { DRb.stop_service; _self.drb_start(port) }
      trap('INT') { DRb.stop_service }

      DRb.thread.join
    end

    def self.default_uri
      "druby://localhost:#{PORT}"
    end

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

    def self.new_drb_object
      # This returns a proxied instance of Service
      DRb::DRbObject.new_with_uri(default_uri)
    end

  end
end
