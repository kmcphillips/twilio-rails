# frozen_string_literal: true

module Twilio
  module Rails
    module SMS
      # Base class for SMS responders. To define a responder start by generating a sublcass.
      #
      #     rails generate twilio:rails:sms_responder ThankYou
      #
      # This will create a new class in `app/sms_responders/thank_you_responder.rb` which will subclass this class. It
      # must be registered with the framework in the initializer for it to be available. The generator does this.
      #
      #     # config/initializers/twilio_rails.rb
      #     config.sms_responders.register { ThankYouResponder }
      #
      # Then the responder must implement the {#handle?} and {#reply} methods. If the {#handle?} method returns true
      # then the {#reply} method will be called to generate the body of the response, and send that message back as an
      # SMS. Only one responder will be called for a given message.
      #
      # @example
      #   class ThankYouResponder < ::Twilio::Rails::SMS::DelegatedResponder
      #     def handle?
      #       matches?(/thank you/)
      #     end
      #
      #     def reply
      #       "Thank you too!"
      #     end
      #   end
      class DelegatedResponder
        attr_reader :message, :sms_conversation

        class << self
          # Returns the name of the class, without the namespace or the `Responder` suffix.
          #
          # @return [String] the name of the responder.
          def responder_name
            name.demodulize.underscore.gsub(/_responder\Z/, "")
          end
        end

        def initialize(message)
          @message = message
          @sms_conversation = message.sms_conversation
        end

        # Must be implemented by the subclass otherwise will raise a `NoMethodError`. Returns true if this
        # responder should handle the given message. If true then the {#reply} method will be called to generate the
        # body of the response. It has access to the message and the conversation.
        #
        # @return [true, false] true if this responder should handle the given message.
        def handle?
          raise NoMethodError, "#{self.class}#handle? must be implemented."
        end

        # Must be implemented by the subclass otherwise will raise a `NoMethodError`. Returns the body of the
        # message to be sent in response. Will only be called if {#handle?} returns true. It has access to the message
        # and the conversation.
        #
        # @return [String, nil] the body of the response to be sent as SMS, or `nil` if no message should be sent.
        def reply
          raise NoMethodError, "#{self.class}#reply must be implemented."
        end

        protected

        # @return [PhoneCaller, nil] the phone caller associated with the message, or `nil` if none is found.
        def phone_caller
          @phone_caller ||= PhoneCaller.find_by(phone_number: @sms_conversation.from_number)
        end

        # @return [String] the phone number associated with the message.
        def inbound_phone_number
          sms_conversation.number
        end

        # Checks if the received message body contains or matches the given matcher. The matcher can be a string,
        # symbol, or number and it will match anywhere in the body ignoring case. The matcher can also be a regex and
        # it will just call `Regexp#match?` on the body. Raises an error if the matcher cannot be handled.
        #
        # @param matcher [String, Symbol, Numeric, Regexp] the matcher to check against the message body.
        # @return [true, false] true if the message body matches the given matcher.
        def matches?(matcher)
          body = message.body || ""

          case matcher
          when String, Numeric, Symbol
            body.downcase.include?(matcher.to_s.downcase)
          when Regexp
            matcher.match?(body)
          else
            raise Twilio::Rails::SMS::InvalidResponderError, "unkown matcher #{matcher}"
          end
        end
      end
    end
  end
end
