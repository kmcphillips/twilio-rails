# frozen_string_literal: true
module Twilio
  module Rails
    # Provides scopes, validations, and convenience methods for a model that has an attribute `direction` with
    # values "inbound" or "outbound".
    module HasDirection
      extend ActiveSupport::Concern

      included do
        validates :direction, inclusion: { in: ["outbound", "inbound"] }

        scope :outbound, -> { where(direction: "outbound") }
        scope :inbound, -> { where(direction: "inbound") }
      end

      def inbound?
        direction == "inbound"
      end

      def outbound?
        direction == "outbound"
      end
    end
  end
end
