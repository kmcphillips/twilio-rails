# frozen_string_literal: true

module Twilio
  module Rails
    module PhoneNumberFormatter
      # Formats phone numbers using the `phonelib` gem, which is based on the Google libphonenumber library.
      # https://github.com/daddyz/phonelib
      # This attempts to support all phone numbers from all countries using the E.164 format.
      class PhonelibGlobal
        NORTH_AMERICAN_PHONE_NUMBER_REGEX = /\A\([0-9]{3}\) [0-9]{3}-[0-9]{4}\z/

        def initialize
          # None yet, but this is where parsing could be configured to limit or make assumptions
          # based on specific countries or regions.
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into a
        # consistently formatted valid phone number prefixed with 1 and plus, formatted for Twilio. It returns `nil`
        # if it cannot be coerced.
        #
        # @param string [String, Twilio::Rails::PhoneNumber, nil, Object] the input to turn into a phone number string.
        # @return [String, nil] the phone number string or nil.
        def coerce(string)
          p = Phonelib.parse(string)
          return nil unless p.valid?
          p.e164
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and validates it
        # matches the expected format of a phone number.
        #
        # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to validate as a phone number.
        # @return [true, false]
        def valid?(string)
          p = Phonelib.parse(string)
          p.valid?
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into
        # a phone number formatted for URLs. Appropriate to use for `#to_param` in Rails or other controller concerns
        # where a phone number or phone caller can be passed around as a URL parameter.
        #
        # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to turn into a phone number string.
        # @return [String] the phone number string or empty string if invalid.
        def to_param(string)
          p = Phonelib.parse(string)
          return "" unless p.valid?

          if canada_or_usa?(p)
            p.international.sub(/\A\+/, "").gsub(/[^0-9-]/, "").sub(/\A1/, "1-")
          else
            p.international.sub(/\A\+/, "").gsub(/[^0-9-]/, "")
          end
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into a
        # phone number string formatted for display. If the number cannot be coerced to a valid phone number it will be
        # passed through.
        #
        # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to turn into a phone number string.
        # @return [String, Object] the phone number string or the original object if invalid.
        def display(string)
          p = Phonelib.parse(string)
          return string unless p.valid?

          if canada_or_usa?(p)
            "+1 #{p.national}"
          else
            p.international
          end
        end

        private

        def canada_or_usa?(p)
          (p.country == "CA" || p.country == "US") && p.national.match(NORTH_AMERICAN_PHONE_NUMBER_REGEX)
        end
      end
    end
  end
end
