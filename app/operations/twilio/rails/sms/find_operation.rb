# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      # Called by {Twilio::Rails::SMSController} with the Twilio params to find an existing SMS conversation.
      class FindOperation < ApplicationOperation
        input :sms_conversation_id, accepts: Integer, type: :keyword, required: true

        def execute
          ::Twilio::Rails.config.sms_conversation_class.find(sms_conversation_id)
        end
      end
    end
  end
end
