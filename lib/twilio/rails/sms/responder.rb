
# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      # The class responsible for pattern matching and delegating how to handle an incoming SMS. Called by
      # {Twilio::Rails::SMS::Twiml::MessageOperation} to generate the body of the response. For a given message it
      # iterates over all registered `sms_responders` and replies with the first one that handles, or raises if none
      # are found to handle the message.
      class Responder
        attr_reader :message, :sms_conversation

        def initialize(message)
          @message = message
          @sms_conversation = message.sms_conversation
        end

        # Iterates over all registered `sms_responders` and replies with the first one that handles, or raises if none
        # are found to handle the message.
        #
        # @return [String] the body of the response.
        def respond
          Twilio::Rails.config.sms_responders.all.each do |name, responder_class|
            responder = responder_class.new(message)
            return responder.reply if responder.handle?
          end

          raise Twilio::Rails::SMS::InvalidResponderError, "No responder found for SMS. message_id=#{ message.id } "\
            "phone_caller_id=#{ sms_conversation.phone_caller&.id } from_number=\"#{ sms_conversation.from_number }\" body=\"#{ message.body }\""
        end
      end
    end
  end
end
