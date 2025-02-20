# frozen_string_literal: true

module Twilio
  module Rails
    # An abstraction over top of the `Twilio::REST` API client. Used to send SMS messages and start calls, as well as
    # return an initialized client if needed.
    module Client
      extend self

      # @return [Twilio::REST::Client] Twilio client initialized with `account_sid` and `auth_token` from the config.
      def client
        @twilio_client ||= Twilio::REST::Client.new(
          Twilio::Rails.config.account_sid,
          Twilio::Rails.config.auth_token
        )
      end

      # Do not call this directly, instead see {Twilio::Rails::SMS::SendOperation}. Send an SMS message to and from the
      # given phone numbers using the Twilio REST API directly. This does not store or manage any interactions in the
      # database.
      #
      # @param message [String] the message to send.
      # @param to [String] the phone number to send the message to.
      # @param from [String] the phone number to send the message from.
      # @return [String] the SID returned from Twilio for the sent SMS message.
      def send_message(message:, to:, from:)
        Twilio::Rails.config.logger.tagged(self) { |l| l.info("[send_message] to=#{to} from=#{from} body='#{message}'") }
        client.messages.create(
          from: from,
          to: to,
          body: message,
          status_callback: "#{Twilio::Rails.config.host}#{::Twilio::Rails::Engine.routes.url_helpers.sms_status_path(format: :xml)}"
        ).sid
      end

      # Do not call this directly, instead see {Twilio::Rails::SMS::SendOperation}. Sends multiple SMS messages to and
      # from the given phone numbers using the Twilio REST API directly. This does not store or manage any interactions
      # in the database. If a message is blank it will be ignored.
      #
      # @param messages [Array<String>] the messages to send.
      # @param to [String] the phone number to send the messages to.
      # @param from [String] the phone number to send the messages from.
      # @return [Array<String>] the SIDs returned from Twilio for the sent SMS messages.
      def send_messages(messages:, to:, from:)
        Twilio::Rails.config.logger.tagged(self) { |l| l.info("[send_messages] to blank messages") } if messages.blank?
        messages.map { |m| send_message(message: m, to: to, from: from) }
      end

      # Do not call this directly, instead see {Twilio::Rails::Phone::StartCallOperation}. Starts a phone call to and
      # from the given phone numbers using the Twilio REST API directly. This does not store or manage any interactions
      # in the database. The URL should come from the {Twilio::Rails::Phone::Tree} that is being used to start the call.
      #
      # @param url [String] the URL to use for the Twilio REST API call, probably from the {Twilio::Rails::Phone::Tree}.
      # @param to [String] the phone number to make the call to.
      # @param from [String] the phone number to make the call from.
      # @param answering_machine_detection [true, false] whether or not to enable answering machine detection.
      # @return [String] the SID returned from Twilio for the started call.
      def start_call(url:, to:, from:, answering_machine_detection: true)
        Twilio::Rails.config.logger.tagged(self) { |l| l.info("[start_call] to=#{to} from=#{from} url=#{url} answering_machine_detection=#{!!answering_machine_detection}") }
        client.calls.create(
          from: from,
          to: to,
          url: url,
          machine_detection: (answering_machine_detection ? "Enable" : "Disable"),
          async_amd: true,
          async_amd_status_callback: "#{Twilio::Rails.config.host}#{::Twilio::Rails::Engine.routes.url_helpers.phone_status_path(format: :xml, async_amd: "true")}",
          async_amd_status_callback_method: "POST",
          status_callback: "#{Twilio::Rails.config.host}#{::Twilio::Rails::Engine.routes.url_helpers.phone_status_path(format: :xml)}",
          status_callback_method: "POST",
          status_callback_event: ["completed", "no-answer"]
          # timeout: 30,
        ).sid
      end
    end
  end
end
