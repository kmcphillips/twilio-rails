# frozen_string_literal: true
module Twilio
  module Rails
    # Provides convenience scopes for a model that has a `created_at` attribute.
    module HasTimeScopes
      extend ActiveSupport::Concern

      included do
        scope :in_last, ->(time) { where(created_at: (Time.now - time)..(Time.now)) }
        scope :in_previous, ->(time) { where(created_at: (Time.now - time - time)..(Time.now - time)) }

        scope :in_last_24_hours, -> { in_last(1.day) }
        scope :in_last_2_days, -> { in_last(2.days) }
        scope :in_last_4_hours, -> { in_last(4.hours) }
        scope :in_previous_24_hours, -> { in_previous(1.day) }
      end
    end
  end
end
