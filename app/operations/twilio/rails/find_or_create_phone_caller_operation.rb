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

        if phone_caller.new_record?
          phone_caller.country_code = lookup_country_code
          phone_caller.save!
        elsif phone_caller.country_code.blank?
          country_code = lookup_country_code
          phone_caller.update!(country_code: country_code) if country_code.present?
        end

        phone_caller
      end

      private

      def valid_phone_number
        Twilio::Rails::PhoneNumberFormatter.coerce(phone_number)
      end

      def lookup_country_code
        Twilio::Rails::Client.country_code(valid_phone_number)
      rescue Twilio::REST::RestError => e
        if e.code == 20404
          ::Rails.error.report(e,
            handled: false,
            context: {
              message: "Country code could not be found for phone number and was left blank.",
              phone_number: valid_phone_number
            })
        else
          ::Rails.error.report(e,
            handled: false,
            context: {
              message: "Failed to get country code for phone number.",
              phone_number: valid_phone_number
            })
        end
        nil
      rescue Twilio::REST::TwilioError => e
        ::Rails.error.report(e,
          handled: false,
          context: {
            message: "Failed to get country code for phone number.",
            phone_number: valid_phone_number
          })
        nil
      rescue => e
        # This is a pretty bad error, but failing to create a phone caller when asked is worse, so report it and continue. It can always be backfilled.
        ::Rails.error.report(e,
          handled: false,
          context: {
            message: "Unexpected error when trying to get country code for phone number.",
            phone_number: valid_phone_number
          })
        nil
      end
    end
  end
end
