# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      module Twiml
        class ErrorOperation < ::Twilio::Rails::ApplicationOperation
          def execute
            twiml = Twilio::TwiML::MessagingResponse.new
            twiml.to_s
          end
        end
      end
    end
  end
end
