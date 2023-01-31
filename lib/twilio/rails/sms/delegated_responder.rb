# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      class DelegatedResponder
        attr_reader :message, :sms_conversation

        class << self
          def responder_name
            self.name.demodulize.underscore.gsub(/_responder\Z/, "")
          end
        end

        def initialize(message)
          @message = message
          @sms_conversation = message.sms_conversation
        end

        def handle?
          raise NotImplementedError
        end

        def reply
          raise NotImplementedError
        end

        protected

        def phone_caller
          @phone_caller ||= PhoneCaller.find_by(phone_number: @sms_conversation.from_number)
        end

        def inbound_phone_number
          sms_conversation.number
        end

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
