# frozen_string_literal: true
module Twilio
  module Rails
    module SMS
      # Base error class for errors relating to Twilio phone interactions.
      class Error < ::Twilio::Rails::Error ; end

      # Error raised when a responder is unable to handle an SMS message.
      class InvalidResponderError < Error ; end
    end
  end
end
