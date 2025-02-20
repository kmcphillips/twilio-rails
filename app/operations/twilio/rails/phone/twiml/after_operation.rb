# frozen_string_literal: true

module Twilio
  module Rails
    module Phone
      module Twiml
        class AfterOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
          input :after, accepts: Twilio::Rails::Phone::Tree::After, type: :keyword, required: true

          def execute
            unless after.hangup?
              next_response = phone_call.responses.build(prompt_handle: after.prompt)
              next_response.save!
            end

            twiml_response = Twilio::TwiML::VoiceResponse.new do |twiml|
              add_messages(twiml, message_set: after.messages, response: next_response)

              if after.hangup?
                twiml.hangup
              else
                twiml.redirect(::Twilio::Rails::Engine.routes.url_helpers.phone_prompt_path(
                  format: :xml,
                  tree_name: tree.name,
                  response_id: next_response.id
                ))
              end
            end

            Twilio::Rails.config.logger.info("after_twiml: #{twiml_response}")
            twiml_response.to_s
          end
        end
      end
    end
  end
end
