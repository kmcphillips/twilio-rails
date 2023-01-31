# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class FindOperation < ::Twilio::Rails::ApplicationOperation
        input :params, accepts: Hash, type: :keyword, required: true

        def execute
          ::Twilio::Rails.config.phone_call_class.find_by!(sid: params["CallSid"])
        end
      end
    end
  end
end
