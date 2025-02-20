# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      class ReceiveRecordingOperation < ::Twilio::Rails::Phone::BaseOperation
        input :params, accepts: Hash, type: :keyword, required: true
        input :response_id, accepts: Integer, type: :keyword, required: true

        def execute
          response = phone_call.responses.find(response_id)

          if phone_call.recordings.sid(params["RecordingSid"]).any?
            Twilio::Rails.config.logger.tagged(self.class) { |l| l.warn("duplicate recording for response_id=#{response.id} recording_sid=#{params["RecordingSid"]}") }
          else
            recording = phone_call.recordings.build(
              recording_sid: params["RecordingSid"],
              url: params["RecordingUrl"],
              duration: params["RecordingDuration"].presence
            )
            recording.save!

            response.recording = recording
            response.save!

            if Twilio::Rails.config.attach_recording?(recording)
              Twilio::Rails::Phone::AttachRecordingJob.set(wait: 5.seconds).perform_later(recording_id: recording.id)
            end

            recording
          end
        end
      end
    end
  end
end
