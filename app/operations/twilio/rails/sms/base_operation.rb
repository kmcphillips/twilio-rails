# frozen_string_literal: true

module Twilio
  module Rails
    module SMS
      # Base class for all SMS operations. Requires the `sms_conversation_id` to be passed in.
      class BaseOperation < ::Twilio::Rails::ApplicationOperation
        input :sms_conversation_id, accepts: Integer, type: :keyword, required: true

        protected

        def conversation
          @conversation ||= ::Twilio::Rails.config.sms_conversation_class.find(sms_conversation_id)
        end
      end
    end
  end
end
