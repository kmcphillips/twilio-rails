# frozen_string_literal: true

module Twilio
  module Rails
    module Formatter
      extend self

      # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into a
      # consistently formatted valid north american 10 digit phone number prefixed with 1 and plus. It uses the format
      # Twilio expects which is "+15555555555" or returns `nil` if it cannot be coerced.
      #
      # @param string [String, Twilio::Rails::PhoneNumber, nil, Object] the input to turn into a phone number string.
      # @return [String, nil] the phone number string or nil.
      def coerce_to_valid_phone_number(string)
        Twilio::Rails.deprecator.warn(<<~DEPRECATION.strip)
          Twilio::Rails::Formatter#coerce_to_valid_phone_number(s) is deprecated and will be removed in the next major version.

          Set Twilio::Rails.config.phone_number_formatter = Twilio::Rails::PhoneNumberFormatter::NorthAmerica.new
          and use Twilio::Rails.config.phone_number_formatter.coerce(s) instead.
        DEPRECATION
        north_america_formatter.coerce(string)
      end

      # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and validates it
      # matches the expected format "+15555555555" of a north american phone number.
      #
      # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to validate as a phone number.
      # @return [true, false]
      def valid_north_american_phone_number?(phone_number)
        Twilio::Rails.deprecator.warn(<<~DEPRECATION.strip)
          Twilio::Rails::Formatter#valid_north_american_phone_number?(s) is deprecated and will be removed in the next major version.

          Set Twilio::Rails.config.phone_number_formatter = Twilio::Rails::PhoneNumberFormatter::NorthAmerica.new
          and use Twilio::Rails.config.phone_number_formatter.valid?(s) instead.
        DEPRECATION
        north_america_formatter.valid?(phone_number)
      end

      # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into
      # a phone number formatted for URLs. Appropriate to use for `#to_param` in Rails or other controller concerns
      # where a phone number or phone caller can be passed around as a URL parameter.
      #
      # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to turn into a phone number string.
      # @return [String] the phone number string or empty string if invalid.
      def to_phone_number_url_param(phone_number)
        Twilio::Rails.deprecator.warn(<<~DEPRECATION.strip)
          Twilio::Rails::Formatter#to_phone_number_url_param(s) is deprecated and will be removed in the next major version.

          Set Twilio::Rails.config.phone_number_formatter = Twilio::Rails::PhoneNumberFormatter::NorthAmerica.new
          and use Twilio::Rails.config.phone_number_formatter.to_param(s) instead.
        DEPRECATION
        north_america_formatter.to_param(phone_number)
      end

      # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into a
      # phone number string formatted for display. If the number cannot be coerced to a valid phone number it will be
      # passed through.
      #
      # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to turn into a phone number string.
      # @return [String, Object] the phone number string or the original object if invalid.
      def display_phone_number(phone_number)
        Twilio::Rails.deprecator.warn(<<~DEPRECATION.strip)
          Twilio::Rails::Formatter#display_phone_number(s) is deprecated and will be removed in the next major version.

          Set Twilio::Rails.config.phone_number_formatter = Twilio::Rails::PhoneNumberFormatter::NorthAmerica.new
          and use Twilio::Rails.config.phone_number_formatter.display(s) instead.
        DEPRECATION
        north_america_formatter.display(phone_number)
      end

      # Formats a city, province, and country into a single string, correctly handling blanks, and formatting countries.
      #
      # @param city [String, nil] the city name.
      # @param province [String, nil] the province name.
      # @param country [String, nil] the country code.
      # @return [String] the formatted location string.
      def location(city: nil, country: nil, province: nil)
        country_name = case country
        when "CA" then "Canada"
        when "US" then "USA"
        else
          country
        end

        [
          city.presence&.titleize,
          province,
          country_name
        ].reject(&:blank?).join(", ")
      end

      private

      def north_america_formatter
        @north_america_formatter ||= Twilio::Rails::PhoneNumberFormatter::NorthAmerica.new
      end
    end
  end
end
