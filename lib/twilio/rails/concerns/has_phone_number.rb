# frozen_string_literal: true

module Twilio
  module Rails
    # Provides validations and reformatting on validation for a model that has an attribute `phone_number` that is
    # that is unique and that matches {Twilio::Rails::Formatter.coerce_to_valid_phone_number}.
    module HasPhoneNumber
      extend ActiveSupport::Concern

      included do
        validates :phone_number, uniqueness: {allow_blank: true, message: "already exists"}

        before_validation :reformat_phone_number
      end

      def reformat_phone_number
        current = Twilio::Rails::Formatter.coerce_to_valid_phone_number(phone_number)
        self.phone_number = current if current

        true
      end

      def valid_north_american_phone_number?
        Twilio::Rails::Formatter.valid_north_american_phone_number?(phone_number)
      end
    end
  end
end
