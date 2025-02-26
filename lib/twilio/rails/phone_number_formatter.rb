# frozen_string_literal: true

module Twilio
  module Rails
    # The interface for the phone number validator and formatter that is defined in the `Twilio::Rails.config.phone_number_formatter`
    # configuration. This delegates the methods to that instance and is used both internally to the gem and by the gem consumer.
    module PhoneNumberFormatter
      extend self
      extend Forwardable

      class Error < Twilio::Rails::Error; end

      def_delegators :formatter, :coerce, :valid?, :to_param, :display

      def coerce!(number)
        coerce(number) || raise(Error, "Could not coerce valid phone number from: #{number}")
      end

      private

      def formatter
        Twilio::Rails.config.phone_number_formatter
      end
    end
  end
end
