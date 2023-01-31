# frozen_string_literal: true
module Twilio
  module Rails
    module Models
      # A conversation via SMS. Has many {Twilio::Rails::Models::Message}s. Each message has a direction and can be
      # unrolled into a full conversation.
      module SMSConversation
        extend ActiveSupport::Concern

        included do
          has_many :messages, dependent: :destroy, class_name: Twilio::Rails.config.message_class_name

          scope :recent, -> { order(created_at: :desc).limit(10) }
          scope :phone_number, ->(number) { where(from_number: number) }
        end

        def phone_caller
          Twilio::Rails.config.phone_caller_class.for(from_number)
        end

        # @return [String] A well formatted string with the city/state/country of the phone number if available.
        def location
          Twilio::Rails::Formatter.location(city: from_city, country: from_country, province: from_province)
        end
      end
    end
  end
end
