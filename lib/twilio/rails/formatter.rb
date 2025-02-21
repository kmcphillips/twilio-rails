# frozen_string_literal: true

module Twilio
  module Rails
    module Formatter
      extend self

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
    end
  end
end
