# frozen_string_literal: true

module Twilio
  module Rails
    module PhoneNumberFormatter
      # Formats phone numbers as North American 10 digit numbers only, and treats any other number as invalid.
      # This is the legacy behavior from 1.0 which will be the default still in 1.1 as an upgrade path.
      class NorthAmerica
        PHONE_NUMBER_REGEX = /\A\+1[0-9]{10}\Z/
        PHONE_NUMBER_SEGMENTS_REGEX = /\A\+1([0-9]{3})([0-9]{3})([0-9]{4})\Z/

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into a
        # consistently formatted valid north american 10 digit phone number prefixed with 1 and plus. It uses the format
        # Twilio expects which is "+15555555555" or returns `nil` if it cannot be coerced.
        #
        # @param string [String, Twilio::Rails::PhoneNumber, nil, Object] the input to turn into a phone number string.
        # @return [String, nil] the phone number string or nil.
        def coerce(string)
          string = string.number if string.is_a?(Twilio::Rails::PhoneNumber)
          string = string.to_s.presence

          if string
            string = string.gsub(/[^0-9]/, "")
            string = "1#{string}" unless string.starts_with?("1")
            string = "+#{string}"
            string = nil unless valid?(string)
          end

          string
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and validates it
        # matches the expected format "+15555555555" of a north american phone number.
        #
        # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to validate as a phone number.
        # @return [true, false]
        def valid?(string)
          string = string.number if string.is_a?(Twilio::Rails::PhoneNumber)
          !!string&.match?(PHONE_NUMBER_REGEX)
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into
        # a phone number formatted for URLs. Appropriate to use for `#to_param` in Rails or other controller concerns
        # where a phone number or phone caller can be passed around as a URL parameter.
        #
        # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to turn into a phone number string.
        # @return [String] the phone number string or empty string if invalid.
        def to_param(string)
          string = coerce(string)
          return "" unless string
          matches = string.match(PHONE_NUMBER_SEGMENTS_REGEX)
          raise Twilio::Rails::Error, "[to_param] Phone number marked as valid but could not capture. I made a bad regex: #{string}" unless matches
          matches.captures.join("-")
        end

        # Takes in a string or a {Twilio::Rails::PhoneNumber} or something that responds to `to_s` and turns it into a
        # phone number string formatted for display. If the number cannot be coerced to a valid phone number it will be
        # passed through.
        #
        # @param phone_number [String, Twilio::Rails::PhoneNumber, nil] the input to turn into a phone number string.
        # @return [String, Object] the phone number string or the original object if invalid.
        def display(string)
          coerced_phone_number = coerce(string)
          if coerced_phone_number
            matches = coerced_phone_number.match(PHONE_NUMBER_SEGMENTS_REGEX)
            raise Twilio::Rails::Error, "[display] Phone number marked as valid but could not capture. I made a bad regex: #{string}" unless matches
            "(#{matches.captures[0]}) #{matches.captures[1]} #{matches.captures[2]}"
          else
            string
          end
        end
      end
    end
  end
end
