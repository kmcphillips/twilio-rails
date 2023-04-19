# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class FinishedCallOperation < ::Twilio::Rails::Phone::BaseOperation
        def execute
          if phone_call.finished?
            Twilio::Rails.config.logger.tagged(self.class) { |l| l.warn("Skipping duplicate finished call job") }
          else
            phone_call.update!(finished: true)
            phone_call.tree.finished_call.call(phone_call) if phone_call.tree.finished_call
          end
        end
      end
    end
  end
end
