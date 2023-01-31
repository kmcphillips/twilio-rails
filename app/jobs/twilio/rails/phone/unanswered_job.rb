# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      # Performs the {Twilio::Rails::Phone::UnansweredOperation}.
      class UnansweredJob < ::Twilio::Rails::ApplicationJob
        queue_as :default

        def perform(phone_call_id:)
          Twilio::Rails::Phone::UnansweredOperation.call(phone_call_id: phone_call_id)
        end
      end
    end
  end
end
