# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class ErrorOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
          input :messages, accepts: Object, type: :keyword, required: false

          def execute
            twiml = Twilio::TwiML::VoiceResponse.new
            add_messages(twiml, message_set: messages, response: phone_call.responses.build) if messages
            twiml.hangup

            Twilio::Rails.config.logger.info("error_twiml: #{twiml.to_s}")
            twiml.to_s
          end
        end
      end
    end
  end
end
