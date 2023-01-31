# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class UpdateOperation < ::Twilio::Rails::Phone::BaseOperation
        input :params, accepts: Hash, type: :keyword, required: true

        def execute
          if phone_call.outbound?
            if params["AnsweredBy"].present? && phone_call.answered_by != params["AnsweredBy"]
              phone_call.answered_by = params["AnsweredBy"]
            end
          end

          if params["CallStatus"].present? && phone_call.call_status != params["CallStatus"]
            phone_call.call_status = params["CallStatus"]
          end

          phone_call.save! if phone_call.changed?

          phone_call
        end
      end
    end
  end
end
