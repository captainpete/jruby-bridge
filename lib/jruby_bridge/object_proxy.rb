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

        class << self
          alias :proxied_new :new
          def new(*args)
            Service.new_drb_object.remote_proxied_new self, *args
          end
        end

      end # base.class_eval
    end # self.included

  end
end
