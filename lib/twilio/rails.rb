require "active_operation"
require "twilio-ruby"
require "faraday"

require "twilio/rails/version"
require "twilio/rails/engine"

module Twilio
  module Rails
    # Base error class for all errors raised by the Twilio::Rails gem. Every error is a subclass of this one.
    class Error < StandardError ; end
  end
end

require "twilio/rails/railtie"
require "twilio/rails/configuration"
require "twilio/rails/formatter"
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

      # Abstraction for the framework to notify of an important exception that has occurred. This safely calls the
      # configured `config.exception_notifier` or does nothing if it is set to `nil`. This does not catch, handle, or
      # prevent the exception from raising.
      #
      # @param exception [Exception] the exception that has occurred.
      # @param message [String] a description of the exception, defaults to `exception.message` if blank.
      # @param context [Hash] a hash of arbitrary additional context to include in the notification.
      # @param exception_binding [Binding] the binding of where the exception is being notified.
      # @return [true, false] if an exception has been successfully notified.
      def notify_exception(exception, message: nil, context: {}, exception_binding: nil)
        if config.exception_notifier
          begin
            message = message.presence || exception.message
            config.exception_notifier.call(exception, message, context, exception_binding)
            true
          rescue => e
            config.logger.tagged(self.class) { |l| l.error("ExceptionNotifier failed to notify of exception=#{ exception.inspect } message=#{ message.inspect } context=#{ context.inspect }") }
            false
          end
        else
          false
        end
      end
    end
  end
end
