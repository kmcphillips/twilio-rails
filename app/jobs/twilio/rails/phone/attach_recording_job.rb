# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      # Performs the {Twilio::Rails::Phone::AttachRecordingOperation}.
      class AttachRecordingJob < ::Twilio::Rails::ApplicationJob
        queue_as :default

        def perform(recording_id:)
          Twilio::Rails::Phone::AttachRecordingOperation.call(recording_id: recording_id)
        end
      end
    end
  end
end
