# frozen_string_literal: true
module Twilio
  module Rails
    # A phone number object that includes the country and some optional metadata.
    class PhoneNumber
      attr_reader :number, :country, :label, :project

      # @param number [String] the phone number string.
      # @param country [String] the country code.
      # @param label [String, nil] an optional label for the phone number, such as its source or purpose.
      # @param project [String, nil] an optional project identifier for grouping phone numbers.
      def initialize(number:, country:, label: nil, project: nil)
        @number = Twilio::Rails::Formatter.coerce_to_valid_phone_number(number)
        raise Twilio::Rails::Phone::Error, "Invalid phone number '#{ number }'" unless @number
        @country = country&.upcase
        @label = label
        @project = project.presence&.to_s
      end

      # @return [String] a human readable string representation of the phone number and its metadata.
      def to_s
        s = "Phone number #{ number } (#{ country })"
        s = "#{ s } #{ label }" if label.present?
        s = "#{ s } for #{ project }" if project.present?
        s
      end
    end
  end
end
