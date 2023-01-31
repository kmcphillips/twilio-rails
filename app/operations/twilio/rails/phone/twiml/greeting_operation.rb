# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class GreetingOperation < Twilio::Rails::Phone::Twiml::BaseOperation
          input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true

          def execute
            if !phone_caller.valid_north_american_phone_number? && tree.config[:invalid_phone_number]
              Twilio::Rails::Phone::Twiml::ErrorOperation.call(phone_call_id: phone_call.id, tree: tree, messages: tree.config[:invalid_phone_number])
            else
              after = tree.greeting
              after = Twilio::Rails::Phone::Tree::After.new(after.proc.call(phone_call.responses.build)) if after.proc
              Twilio::Rails::Phone::Twiml::AfterOperation.call(phone_call_id: phone_call.id, tree: tree, after: after)
            end
          end
        end
      end
    end
  end
end
