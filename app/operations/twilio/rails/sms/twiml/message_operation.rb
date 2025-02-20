# frozen_string_literal: true

module Twilio
  module Rails
    module SMS
      module Twiml
        class MessageOperation < Twilio::Rails::SMS::Twiml::BaseOperation
          input :params, accepts: Hash, type: :keyword, required: true

          def execute
            inbound_message = conversation.messages.build(
              direction: "inbound",
              body: params["Body"],
              sid: params["SmsSid"].presence || params["MessageSid"].presence
            )

            inbound_message.save!

            body = Twilio::Rails::SMS::Responder.new(inbound_message).respond

            if body.present?
              message = conversation.messages.build(
                direction: "outbound",
                body: body
              )

              message.save!

              twiml_response = Twilio::TwiML::MessagingResponse.new do |twiml|
                twiml.message(
                  body: body,
                  action: ::Twilio::Rails::Engine.routes.url_helpers.sms_status_message_path(message_id: message.id)
                )
              end

              Twilio::Rails.config.logger.info("message_twiml: #{twiml_response}")
              twiml_response.to_s
            else
              Twilio::Rails.config.logger.info("resply is blank, not sending message in response")
              Twilio::Rails.config.logger.info("message_twiml: #{twiml_response}")

              twiml = Twilio::TwiML::MessagingResponse.new
              twiml.to_s
            end
          end
        end
      end
    end
  end
end
