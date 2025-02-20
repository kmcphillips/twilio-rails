# frozen_string_literal: true

module Twilio
  module Rails
    module SMS
      # Public entrypoint used to send an SMS message. This operation will create a new conversation to the phone caller
      # and send a series of messages to them. The interaction will be stored in the database and sent via Twilio's API.
      # The operation will raise if the {#from_number} is not a valid phone number.
      #
      # @example
      #   Twilio::Rails::SMS::SendOperation.call(
      #     phone_caller_id: a_phone_caller.id,
      #     messages: ["Hello world!"],
      #     from_number: "+1234567890"
      #   )
      #
      # *Note:* Operations should be called with `call(params)` and not by calling `new(params).execute` directly.
      class SendOperation < ApplicationOperation
        input :phone_caller_id, accepts: Integer, type: :keyword, required: true
        input :messages, accepts: Array, type: :keyword, required: true
        input :from_number, accepts: [String, Twilio::Rails::PhoneNumber], type: :keyword, required: false

        TWILIO_UNSUBSCRIBED_ERROR_CODES = [21610].freeze

        # @param phone_caller_id [Integer] the id of the phone caller to send the message to.
        # @param messages [Array<String>] the messages to send to the phone caller. It may be empty.
        # @param from_number [String, Twilio::Rails::PhoneNumber] the phone number to send the message from. If the
        # number is `nil` then it will attempt to extract the phone number from the last phone call. If that is not found
        # then it will raise {Twilio::Rails::SMS::Error}.
        # @return [Twilio::Rails::Models::SMSConversation] the SMS conversation that was created and sent.
        def execute
          return nil if messages.blank?
          raise Twilio::Rails::SMS::Error, "from_number=#{from_number} is not a valid phone number" if from_number.present? && !Twilio::Rails::Formatter.coerce_to_valid_phone_number(from_number)

          conversation = ::Twilio::Rails.config.sms_conversation_class.new(
            number: calculated_from_number,
            from_number: calculated_to_number,
            from_city: phone_call&.from_city,
            from_province: phone_call&.from_province,
            from_country: phone_call&.from_country
          )
          conversation.save!

          messages.each do |body|
            sid = nil
            begin
              sid = Twilio::Rails::Client.send_message(
                message: body,
                to: calculated_to_number,
                from: calculated_from_number
              )
            rescue Twilio::REST::RestError => e
              if TWILIO_UNSUBSCRIBED_ERROR_CODES.include?(e.code)
                Twilio::Rails.config.logger.tagged(self.class) { |l| l.warn("tried to send to unsubscribed and got Twilio::REST::RestError code=21610 phone_caller_id=#{phone_caller.id} phone_number=#{calculated_to_number} message=#{body}") }
              else
                ::Rails.error.report(e,
                  handled: false,
                  context: {
                    message: "Failed to send Twilio message. Got REST error response.",
                    to: calculated_to_number,
                    from: calculated_from_number,
                    phone_call_id: phone_call&.id
                  })
                raise
              end
            end

            message = conversation.messages.build(body: body, sid: sid, direction: "outbound")

            message.save!
          end

          conversation
        end

        private

        def phone_caller
          @phone_caller ||= ::Twilio::Rails.config.phone_caller_class.find(phone_caller_id)
        end

        def phone_call
          @phone_call ||= phone_caller.phone_calls.inbound.last
        end

        def calculated_from_number
          if from_number.present?
            Twilio::Rails::Formatter.coerce_to_valid_phone_number(from_number)
          elsif phone_call
            phone_call.number
          else
            raise Twilio::Rails::SMS::Error, "Cannot find a valid from_number to send from"
          end
        end

        def calculated_to_number
          phone_caller.phone_number
        end
      end
    end
  end
end
