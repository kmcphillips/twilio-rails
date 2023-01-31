# frozen_string_literal: true
module Twilio
  module Rails
    class PhoneController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :validate_webhook

      def inbound
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::CreateOperation.call(params: params_hash, tree: tree)
            render xml: Twilio::Rails::Phone::Twiml::GreetingOperation.call(phone_call_id: phone_call.id, tree: tree)
          end
        end
      end

      def outbound
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            render xml: Twilio::Rails::Phone::Twiml::GreetingOperation.call(phone_call_id: phone_call.id, tree: tree)
          end
        end
      end

      def prompt
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            phone_call = Twilio::Rails::Phone::UpdateOperation.call(phone_call_id: phone_call.id, params: params_hash)
            render xml: Twilio::Rails::Phone::Twiml::PromptOperation.call(phone_call_id: phone_call.id, tree: tree, response_id: params[:response_id].to_i)
          end
        end
      end

      def prompt_response
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            phone_call = Twilio::Rails::Phone::UpdateOperation.call(phone_call_id: phone_call.id, params: params_hash)
            render xml: Twilio::Rails::Phone::Twiml::PromptResponseOperation.call(phone_call_id: phone_call.id, tree: tree, response_id: params[:response_id].to_i, params: params_hash)
          end
        end
      end

      def timeout
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            phone_call = Twilio::Rails::Phone::UpdateOperation.call(phone_call_id: phone_call.id, params: params_hash)
            render xml: Twilio::Rails::Phone::Twiml::TimeoutOperation.call(phone_call_id: phone_call.id, tree: tree, response_id: params[:response_id].to_i)
          end
        end
      end

      def transcribe
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            Twilio::Rails::Phone::UpdateResponseOperation.call(phone_call_id: phone_call.id, response_id: params[:response_id].to_i, params: params_hash)

            head :ok
          end
        end
      end

      def status
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            phone_call = Twilio::Rails::Phone::UpdateOperation.call(phone_call_id: phone_call.id, params: params_hash)

            head :ok
          end
        end
      end

      def receive_response_recording
        respond_to do |format|
          format.xml do
            phone_call = Twilio::Rails::Phone::FindOperation.call(params: params_hash)
            Twilio::Rails::Phone::ReceiveRecordingOperation.call(phone_call_id: phone_call.id, response_id: params[:response_id].to_i, params: params_hash)

            head :ok
          end
        end
      end

      private

      def validate_webhook
        if params["AccountSid"] != Twilio::Rails.config.account_sid
          respond_to do |format|
            format.xml do
              render xml: Twilio::Rails::Phone::Twiml::RequestValidationFailureOperation.call
            end
          end
        end
      end

      def tree
        @tree ||= Twilio::Rails.config.phone_trees.for(params[:tree_name])
      end

      def params_hash
        params.permit!.to_h.except("controller", "action", "format", "response_id", "tree_name")
      end
    end
  end
end
