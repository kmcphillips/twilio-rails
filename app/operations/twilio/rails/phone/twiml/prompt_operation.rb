# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      module Twiml
        class PromptOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
          input :response_id, accepts: Integer, type: :keyword, required: true

          def execute
            return Twilio::Rails::Phone::Twiml::ErrorOperation.call(phone_call_id: phone_call.id, tree: tree) if phone_call.answering_machine?

            response = phone_call.responses.find(response_id)
            prompt = tree.prompts[response.prompt_handle]
            raise Twilio::Rails::Phone::InvalidTreeError, "cannot find #{response.prompt_handle} in #{tree.name}" unless prompt

            twiml_response = Twilio::TwiML::VoiceResponse.new do |twiml|
              unless prompt.gather&.interrupt?
                add_messages(twiml, message_set: prompt.messages, response: response)
              end

              case prompt.gather&.type
              when :digits
                args = {
                  action: ::Twilio::Rails::Engine.routes.url_helpers.phone_prompt_response_path(
                    format: :xml,
                    tree_name: tree.name,
                    response_id: response.id
                  ),
                  input: "dtmf",
                  num_digits: prompt.gather.args[:number],
                  timeout: prompt.gather.args[:timeout],
                  action_on_empty_result: false
                }

                args[:finish_on_key] = prompt.gather.args[:finish_on_key] if prompt.gather.args[:finish_on_key]

                twiml.gather(**args) do |twiml|
                  if prompt.gather&.interrupt?
                    add_messages(twiml, message_set: prompt.messages, response: response)
                  end
                end
                twiml.redirect(::Twilio::Rails::Engine.routes.url_helpers.phone_timeout_path(
                  format: :xml,
                  tree_name: tree.name,
                  response_id: response.id
                ))
              when :voice
                args = {
                  max_length: prompt.gather.args[:length],
                  # trim: "trim-silence",
                  timeout: prompt.gather.args[:timeout],
                  action: ::Twilio::Rails::Engine.routes.url_helpers.phone_prompt_response_path(
                    format: :xml,
                    tree_name: tree.name,
                    response_id: response.id
                  ),
                  recording_status_callback: ::Twilio::Rails::Engine.routes.url_helpers.phone_receive_recording_path(
                    response_id: response.id
                  )
                }

                if prompt.gather.args[:transcribe]
                  args[:transcribe] = true
                  args[:transcribe_callback] = ::Twilio::Rails::Engine.routes.url_helpers.phone_transcribe_path(response_id: response.id)
                end

                args[:profanity_filter] = true if prompt.gather.args[:profanity_filter]

                twiml.record(**args)
              when :speech
                args = {
                  action: ::Twilio::Rails::Engine.routes.url_helpers.phone_prompt_response_path(
                    format: :xml,
                    tree_name: tree.name,
                    response_id: response.id
                  ),
                  input: "speech",
                  timeout: prompt.gather.args[:timeout],
                  action_on_empty_result: true,
                  language: prompt.gather.args[:language].presence || "en-US",
                  enhanced: !!prompt.gather.args[:enhanced]
                }

                args[:speech_timeout] = prompt.gather.args[:speech_timeout] if prompt.gather.args[:speech_timeout]
                args[:speech_model] = prompt.gather.args[:speech_model] if prompt.gather.args[:speech_model].present?
                args[:profanity_filter] = true if prompt.gather.args[:profanity_filter]

                twiml.gather(**args)
              when nil
                twiml.redirect(::Twilio::Rails::Engine.routes.url_helpers.phone_prompt_response_path(
                  format: :xml,
                  tree_name: tree.name,
                  response_id: response.id
                ))
              else
                raise Twilio::Rails::Phone::InvalidTreeError, "unknown gather type #{prompt.gather.type.inspect}"
              end
            end

            Twilio::Rails.config.logger.info("prompt_twiml: #{twiml_response}")
            twiml_response.to_s
          end
        end
      end
    end
  end
end
