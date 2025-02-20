# frozen_string_literal: true

module Twilio
  module Rails
    # Finds and returns a {Twilio::Rails::Models::PhoneCaller} by phone number, or creates a new one if it does not
    # exist. The operation will `halt` if the phone number is not valid or blank.
    #
    # *Note:* Operations should be called with `call(params)` and not by calling `new(params).execute` directly.
    class FindOrCreatePhoneCallerOperation < ::Twilio::Rails::ApplicationOperation
      input :phone_number, accepts: String, type: :keyword, required: false

      # @param phone_number [String] The phone number to find or create the phone caller.
      # @return [Twilio::Rails::Models::PhoneCaller] The found or newly created phone caller.
      def execute
        halt nil unless valid_phone_number

        phone_caller = ::Twilio::Rails.config.phone_caller_class.find_or_initialize_by(phone_number: valid_phone_number)
        phone_caller.save! if phone_caller.new_record?

        phone_caller
      end

      private

      def valid_phone_number
        Twilio::Rails::Formatter.coerce_to_valid_phone_number(phone_number)
      end
    end
  end
end
