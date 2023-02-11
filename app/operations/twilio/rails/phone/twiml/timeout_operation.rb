# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class TimeoutOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
          input :response_id, accepts: Integer, type: :keyword, required: true

          def execute
            return Twilio::Rails::Phone::Twiml::ErrorOperation.call(phone_call_id: phone_call.id, tree: tree) if phone_call.answering_machine?

            response = phone_call.responses.find(response_id)
            response.timeout = true
            response.save!

            if final_timeout?(response, count: tree.config[:final_timeout_attempts])
              twiml_response = Twilio::TwiML::VoiceResponse.new do |twiml|
                add_messages(twiml, message_set: tree.config[:final_timeout_message], response: response)
                twiml.hangup
              end

              Twilio::Rails.config.logger.info("final timeout on phone_call##{ phone_call.id }")
              Twilio::Rails.config.logger.info("timeout_twiml: #{twiml_response.to_s}")
              twiml_response.to_s
            else
              prompt = tree.prompts[response.prompt_handle]
              raise Twilio::Rails::Phone::InvalidTreeError, "cannot find #{ response.prompt_handle } in #{ tree.name }" unless prompt

              after = prompt.after
              after = Twilio::Rails::Phone::Tree::After.new(after.proc.call(response)) if after.proc

              Twilio::Rails::Phone::Twiml::AfterOperation.call(phone_call_id: phone_call.id, tree: tree, after: after)
            end
          end

          private

          def final_timeout?(last_response, count: )
            responses = phone_call.responses.final_timeout_check(count: count, prompt_handle: last_response.prompt_handle)

            responses.count == count && responses.all? { |r| r.timeout? }
          end
        end
      end
    end
  end
end
