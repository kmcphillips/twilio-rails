# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      # Called by {Twilio::Rails::SMSController} with the Twilio params to find an existing SMS message.
      class FindMessageOperation < ApplicationOperation
        input :params, accepts: Hash, type: :keyword, required: true

        def execute
          ::Twilio::Rails.config.message_class.find_by!(sid: params["SmsSid"])
        end
      end
    end
  end
end
