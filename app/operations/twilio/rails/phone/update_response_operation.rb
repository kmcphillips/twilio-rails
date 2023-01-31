# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class UpdateResponseOperation < ::Twilio::Rails::Phone::BaseOperation
        input :params, accepts: Hash, type: :keyword, required: true
        input :response_id, accepts: Integer, type: :keyword, required: true

        def execute
          response = phone_call.responses.find(response_id)

          if params["Digits"].present?
            response.digits = params["Digits"]
          end

          if params["TranscriptionText"].present? && params["TranscriptionStatus"] == "completed"
            response.transcription = params["TranscriptionText"]
            response.transcribed = true
          end

          if params["SpeechResult"].present?
            response.transcription = params["SpeechResult"]
            response.transcribed = true
          end

          response.save! if response.changed?

          if params["RecordingSid"]
            Twilio::Rails::Phone::ReceiveRecordingOperation.call(phone_call_id: phone_call.id, response_id: response.id, params: params)
            response.reload # This attaches to the other end of the association so this instance doesn't know about it without a reload
          end

          response
        end
      end
    end
  end
end
