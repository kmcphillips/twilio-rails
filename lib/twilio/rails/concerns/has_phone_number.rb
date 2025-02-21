# frozen_string_literal: true

module Twilio
  module Rails
    # Provides validations and reformatting on validation for a model that has an attribute `phone_number` that is
    # that is unique and that matches {Twilio::Rails::PhoneNumberFormatter.coerce}.
    module HasPhoneNumber
      extend ActiveSupport::Concern

      included do
        validates :phone_number, uniqueness: {allow_blank: true, message: "already exists"}

        before_validation :reformat_phone_number
      end

      def reformat_phone_number
        current = Twilio::Rails::PhoneNumberFormatter.coerce(phone_number)
        self.phone_number = current if current

        true
      end

      def valid_north_american_phone_number?
        Twilio::Rails.deprecator.warn(<<~DEPRECATION.strip)
          valid_north_american_phone_number? is deprecated and will be removed in the next major version.
          Use valid_phone_number? instead. The configured phone_number_formatter can manage the region of the phone number.
        DEPRECATION
        Twilio::Rails::PhoneNumberFormatter.valid?(phone_number)
      end

      def valid_phone_number?
        Twilio::Rails::PhoneNumberFormatter.valid?(phone_number)
      end
    end
  end
end
