# frozen_string_literal: true

module Twilio
  module Rails
    module Models
      # A recording of a fragment of a phone call gathered from Twilio. See `gather: { type: :voice }` in the
      # documentation for {Twilio::Rails::Phone::BaseTree}. Is associated to one {Twilio::Rails::Models::Response}.
      # Attaches the audio file as an ActiveStorage attachment.
      module Recording
        extend ActiveSupport::Concern

        included do
          belongs_to :phone_call, class_name: Twilio::Rails.config.phone_call_class_name

          has_one :response, class_name: Twilio::Rails.config.response_class_name
          has_one_attached :audio

          scope :sid, ->(sid) { where(recording_sid: sid) }
        end

        # @return [Integer, nil] The length of the recording in seconds, or nil if unavailable.
        def length_seconds
          duration.to_i if duration.present?
        end
      end
    end
  end
end
