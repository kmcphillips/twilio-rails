# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      # Base class for all SMS operations. Requires the `phone_call_id` to be passed in.
      class BaseOperation < ::Twilio::Rails::ApplicationOperation
        input :phone_call_id, accepts: Integer, type: :keyword, required: true

        protected

        def phone_call
          @phone_call ||= ::Twilio::Rails.config.phone_call_class.find(phone_call_id)
        end

        def phone_caller
          phone_call.phone_caller
        end
      end
    end
  end
end
