# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class CreateOperation < ::Twilio::Rails::ApplicationOperation
        input :params, accepts: Hash, type: :keyword, required: true
        input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true

        def execute
          phone_call = ::Twilio::Rails.config.phone_call_class.new(
            sid: params["CallSid"],
            direction: params["direction"].presence || "inbound",
            call_status: params["CallStatus"],
            tree_name: tree.name,
            number: params["Called"].presence || params["To"].presence,
            from_number: params["Caller"].presence || params["From"].presence,
            from_city: params["CallerCity"].presence || params["FromCity"].presence,
            from_province: params["CallerState"].presence || params["FromState"].presence,
            from_country: params["CallerCountry"].presence || params["FromCountry"].presence,
          )

          phone_caller = Twilio::Rails::FindOrCreatePhoneCallerOperation.call(phone_number: phone_call.from_number)

          phone_call.phone_caller = phone_caller
          phone_call.save!

          phone_call
        end
      end
    end
  end
end
