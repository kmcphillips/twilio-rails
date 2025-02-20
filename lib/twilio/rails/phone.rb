# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      # Base error class for errors relating to Twilio phone interactions.
      class Error < ::Twilio::Rails::Error; end

      # Error raised when attempting to build a phone tree.
      class InvalidTreeError < Error; end
    end
  end
end
