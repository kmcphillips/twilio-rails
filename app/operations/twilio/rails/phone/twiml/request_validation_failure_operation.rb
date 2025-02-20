# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      module Twiml
        class RequestValidationFailureOperation < ::Twilio::Rails::ApplicationOperation
          def execute
            twiml = Twilio::TwiML::VoiceResponse.new
            twiml.hangup
            twiml.to_s
          end
        end
      end
    end
  end
end
