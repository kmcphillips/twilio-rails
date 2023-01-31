# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class PromptResponseOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
          input :response_id, accepts: Integer, type: :keyword, required: true
          input :params, accepts: Hash, type: :keyword, required: true

          def execute
            return Twilio::Rails::Phone::Twiml::ErrorOperation.call(phone_call_id: phone_call.id, tree: tree) if phone_call.answering_machine?

            response = phone_call.responses.find(response_id)
            response = Twilio::Rails::Phone::UpdateResponseOperation.call(params: params, response_id: response.id, phone_call_id: phone_call.id)

            prompt = tree.prompts[response.prompt_handle]
            raise Twilio::Rails::Phone::InvalidTreeError, "cannot find #{ response.prompt_handle } in #{ tree.name }" unless prompt

            after = prompt.after
            after = Twilio::Rails::Phone::Tree::After.new(after.proc.call(response)) if after.proc

            Twilio::Rails::Phone::Twiml::AfterOperation.call(phone_call_id: phone_call.id, tree: tree, after: after)
          end
        end
      end
    end
  end
end
