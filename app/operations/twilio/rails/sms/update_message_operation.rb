# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      # Called by {Twilio::Rails::SMSController} with the Twilio params to update an existing SMS message with any
      # status changes or updates that Twilio sends. The save will only happen if there has been a change.
      class UpdateMessageOperation < ApplicationOperation
        input :params, accepts: Hash, type: :keyword, required: true
        input :message_id, accepts: Integer, type: :keyword, required: true

        def execute
          message = ::Twilio::Rails.config.message_class.find(message_id)

          if params["MessageStatus"].present?
            message.status = params["MessageStatus"]
          end

          if message.changed?
            message.save!
          end

          message
        end
      end
    end
  end
end
