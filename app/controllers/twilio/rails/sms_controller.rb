# frozen_string_literal: true

module Twilio
  module Rails
    class SMSController < ::Twilio::Rails::ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :validate_webhook

      def message
        respond_to do |format|
          format.xml do
            if spam?
              render xml: Twilio::Rails::SMS::Twiml::ErrorOperation.call
            else
              if session[:sms_conversation_id].present?
                conversation = Twilio::Rails::SMS::FindOperation.call(sms_conversation_id: session[:sms_conversation_id])
              else
                conversation = Twilio::Rails::SMS::CreateOperation.call(params: params_hash)
                session[:sms_conversation_id] = conversation.id
              end

              render xml: Twilio::Rails::SMS::Twiml::MessageOperation.call(sms_conversation_id: conversation.id, params: params_hash)
            end
          end
        end
      end

      def status
        respond_to do |format|
          format.xml do
            if params[:message_id].present?
              Twilio::Rails::SMS::UpdateMessageOperation.call(message_id: params[:message_id].to_i, params: params_hash)
            else
              message = Twilio::Rails::SMS::FindMessageOperation.call(params: params_hash)
              Twilio::Rails::SMS::UpdateMessageOperation.call(message_id: message.id, params: params_hash)
            end

            head :ok
          end
        end
      end

      private

      def validate_webhook
        if params["AccountSid"] != Twilio::Rails.config.account_sid
          respond_to do |format|
            format.xml do
              render xml: Twilio::Rails::SMS::Twiml::ErrorOperation.call
            end
          end
        end
      end

      def spam?
        Twilio::Rails.config.spam_filter && Twilio::Rails.config.spam_filter.call(params)
      end

      def params_hash
        params.permit!.to_h.except("controller", "action", "format", "message_id", "tree_name")
      end
    end
  end
end
