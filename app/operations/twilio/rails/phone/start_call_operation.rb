# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      class StartCallOperation < ::Twilio::Rails::ApplicationOperation
        input :tree, accepts: Twilio::Rails::Phone::Tree, type: :keyword, required: true
        input :to, accepts: String, type: :keyword, required: true
        input :from, accepts: [String, Twilio::Rails::PhoneNumber], type: :keyword, required: false
        input :answering_machine_detection, accepts: [true, false], default: true, type: :keyword, required: false

        def execute
          from = if self.from.is_a?(Twilio::Rails::PhoneNumber)
            self.from.number
          elsif self.from.present?
            self.from
          else
            Twilio::Rails.config.default_outgoing_phone_number
          end

          params = {
            "CallSid" => nil,
            "direction" => "outbound",
            "To" => from,
            "From" => to,
          }

          begin
            sid = Twilio::Rails::Client.start_call(url: tree.outbound_url, to: to, from: from, answering_machine_detection: answering_machine_detection)
            params["CallSid"] = sid
          rescue Twilio::REST::TwilioError => e
            ::Rails.error.report(e,
              handled: false,
              context: {
                message: "Failed to start Twilio phone call. Got REST error response.",
                params: params,
              }
            )
            raise
          rescue => e
            ::Rails.error.report(e,
              handled: false,
              context: {
                message: "Failed to start Twilio phone call. Got unknown error.",
                params: params,
          }
            )
            raise
          end

          # TODO: I think this may be a race condition
          phone_call = Twilio::Rails::Phone::CreateOperation.call(params: params, tree: tree)
          phone_call
        end
      end
    end
  end
end
