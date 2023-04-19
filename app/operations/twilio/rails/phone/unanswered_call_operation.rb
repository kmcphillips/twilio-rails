# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class UnansweredCallOperation < ::Twilio::Rails::Phone::BaseOperation
        def execute
          if !phone_call.outbound?
            Twilio::Rails.config.logger.tagged(self.class) { |l| l.error("Should never be called on inbound call") }
            halt
          end

          if phone_call.unanswered?
            Twilio::Rails.config.logger.tagged(self.class) { |l| l.warn("Skipping duplicate unanswered call job") }
          else
            phone_call.update!(unanswered: true)
            phone_call.tree.unanswered_call.call(phone_call) if phone_call.tree.unanswered_call
          end
        end
      end
    end
  end
end
