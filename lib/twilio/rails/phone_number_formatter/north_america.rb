# frozen_string_literal: true

module Twilio
  module Rails
    module PhoneNumberFormatter
      # Formats phone numbers as North American 10 digit numbers only, and treats any other number as invalid.
      # This is the legacy behavior from 1.0 which will be the default still in 1.1 as an upgrade path.
      class NorthAmerica
        PHONE_NUMBER_REGEX = /\A\+1[0-9]{10}\Z/
        PHONE_NUMBER_SEGMENTS_REGEX = /\A\+1([0-9]{3})([0-9]{3})([0-9]{4})\Z/

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

        def valid?(string)
          string = string.number if string.is_a?(Twilio::Rails::PhoneNumber)
          !!string&.match?(PHONE_NUMBER_REGEX)
        end

        def to_param(string)
          string = coerce(string)
          return "" unless string
          matches = string.match(PHONE_NUMBER_SEGMENTS_REGEX)
          raise Twilio::Rails::Error, "[to_param] Phone number marked as valid but could not capture. I made a bad regex: #{string}" unless matches
          matches.captures.join("-")
        end

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
