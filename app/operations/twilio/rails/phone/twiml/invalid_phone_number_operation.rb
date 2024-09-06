# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class InvalidPhoneNumberOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
          input :phone_call_id, accepts: Integer, type: :keyword, required: false, default: nil

          def execute
            twiml = Twilio::TwiML::VoiceResponse.new
            messages = tree.config[:invalid_phone_number] || []
            response = phone_call.responses.build if phone_call_id
            add_messages(twiml, message_set: messages, response: response)
            twiml.hangup

            Twilio::Rails.config.logger.info("error_twiml: #{twiml.to_s}")
            twiml.to_s
          end
        end
      end
    end
  end
end
