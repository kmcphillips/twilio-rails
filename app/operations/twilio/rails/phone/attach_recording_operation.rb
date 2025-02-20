# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      # Called by {Twilio::Rails::Phone::ReceiveRecordingOperation} to download and store the audio file from the URL
      # provided by Twilio.
      class AttachRecordingOperation < ::Twilio::Rails::ApplicationOperation
        input :recording_id, accepts: Integer, type: :keyword, required: true

        def execute
          recording = ::Twilio::Rails.config.recording_class.find(recording_id)

          if !recording.audio.attached?
            if recording.url.blank?
              raise Twilio::Rails::Phone::Error, "[AttachRecordingOperation] Has a blank URL and cannot be fetched recording_id=#{recording.id}"
            end

            response = Faraday.get(recording.url)

            if response.success?
              recording.audio.attach(io: StringIO.new(response.body), filename: "recording.wav", content_type: "audio/wav")
              recording.save!
            else
              raise Twilio::Rails::Phone::Error, "[AttachRecordingOperation] Failed to fetch recording recording_id=#{recording.id} HTTP#{response.status} from #{recording.url}"
            end
          end
        end
      end
    end
  end
end
