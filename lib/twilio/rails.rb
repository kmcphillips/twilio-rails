require "forwardable"
require "active_operation"
require "twilio-ruby"
require "faraday"

require "twilio/rails/version"
require "twilio/rails/engine"

module Twilio
  module Rails
    # Base error class for all errors raised by the Twilio::Rails gem. Every error is a subclass of this one.
    class Error < StandardError; end
  end
end

require "twilio/rails/railtie"
require "twilio/rails/configuration"
require "twilio/rails/formatter"
require "twilio/rails/phone_number_formatter"
require "twilio/rails/phone_number_formatter/north_america"
require "twilio/rails/phone_number"
require "twilio/rails/client"

require "twilio/rails/phone"
require "twilio/rails/phone/tree"
require "twilio/rails/phone/base_tree"
require "twilio/rails/phone/tree_macros"

require "twilio/rails/sms"
require "twilio/rails/sms/responder"
require "twilio/rails/sms/delegated_responder"

require "twilio/rails/concerns/has_phone_number"
require "twilio/rails/concerns/has_time_scopes"
require "twilio/rails/concerns/has_direction"
require "twilio/rails/models/phone_caller"
require "twilio/rails/models/recording"
require "twilio/rails/models/phone_call"
require "twilio/rails/models/response"
require "twilio/rails/models/sms_conversation"
require "twilio/rails/models/message"

module Twilio
  module Rails
    class << self
      # Read and write accessible configuration object. In most cases this should only be read after the app has been
      # initialized. See {Twilio::Rails::Configuration} for more information.
      #
      # @return [Twilio::Rails::Configuration] the config object for the engine.
      def config
        @config ||= ::Twilio::Rails::Configuration.new
      end

      # See the ActiveSupport::Deprecation documentation:
      # https://api.rubyonrails.org/classes/ActiveSupport/Deprecation.html
      #
      # @return [ActiveSupport::Deprecation] the deprecator for the engine.
      def deprecator
        @deprecator ||= ActiveSupport::Deprecation.new("2.0", "Twilio::Rails")
      end

      # Called in the `config/initializers/twilio_rails.rb` file to configure the engine. This yields the {.config}
      # object above and then calls {Twilio::Rails::Configuration#validate!} to ensure the configuration is valid.
      #
      # @yield [Twilio::Rails::Configuration] the configuration object.
      # @return [nil]
      def setup
        config.setup!
        yield(config)
        config.validate!
        nil
      end
    end
  end
end
