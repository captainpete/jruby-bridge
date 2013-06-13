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
    PORT = 44344
    # Time to allow JRuby to initialize, in 100-ms increments
    TIMEOUT = 300

    def proxy_new(klass, *args)
      klass.new *args
    end

    def stop
      DRb.stop_service
    end

    def self.with_service(&block)
      start
      yield
    ensure
      stop
    end

    def self.start
      return @pid if @pid
      cls = self
      @pid = Process.fork do
        exit(cls.exec PORT)
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
      raise DRbConnectionError.new("Could not connect to #{default_uri}") if \
            (! connected)
    end

    def self.stop
      service_send :stop
    end

    # Replace current process with JRuby running JRubyBridge::Service
    def self.exec(port)
      jruby = get_jruby
      command = "#{jruby} #{DAEMON} #{port || ''}"
      puts "Running #{command}"
      Kernel.exec command if jruby

      # Note: a raised exception goes nowhere: instead use exit status
      $stderr.puts "No JRUBY found!"
      return 1
    end

    # Called by the server script in JRuby context
    def self.drb_start(port)
      port ||= PORT

      DRb.start_service "druby://localhost:#{port.to_i}", self.new

      cls = self
      trap('HUP') { DRb.stop_service; cls.drb_start(port) }
      trap('INT') { puts 'Stopping jruby service'; DRb.stop_service }

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

    # this will return a new DRuby connection
    def self.service_send(method, *args)
      begin
        new_drb_object.tap { |obj| obj.send(method, *args) }
      rescue DRb::DRbConnError => e
        # $stderr.puts e.backtrace.join("\n")
        raise DRbConnectionError.new(e.message)
      end
    end

    def self.new_drb_object
      DRb::DRbObject.new_with_uri(default_uri)
    end

  end
end
