require 'jruby_bridge/service'

module JRubyBridge

=begin rdoc
A module that patches initialization behavior to cause
new instances to reside on the JRuby DRb service.
=end
  module ObjectProxy

    def self.included(base)
      base.class_eval do
        include DRb::DRbUndumped

        def self.new(*args)
          service = Service.new_drb_object
          service.proxy_new(self, *args)
        end
      end
    end

  end
end
