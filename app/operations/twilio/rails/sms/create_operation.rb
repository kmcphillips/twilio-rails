# frozen_string_literal: true

module Twilio
  module Rails
    module SMS
      # Called by {Twilio::Rails::SMSController} with the Twilio params to create a new SMS conversation.
      class CreateOperation < ApplicationOperation
        input :params, accepts: Hash, type: :keyword, required: true

        def execute
          conversation = ::Twilio::Rails.config.sms_conversation_class.new(
            number: params["Called"].presence || params["To"].presence,
            from_number: params["From"].presence,
            from_city: params["FromCity"].presence,
            from_province: params["FromState"].presence,
            from_country: params["FromCountry"].presence
          )
          conversation.save!
          conversation
        end
      end
    end
  end
end
