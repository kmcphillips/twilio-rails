# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::PhoneController, type: :controller do
  include_examples "twilio phone API call"

  routes { ::Twilio::Rails::Engine.routes }

  let(:phone_call) { create(:phone_call, sid: call_sid) }
  let(:phone_call_response) { create(:response, phone_call: phone_call) } # Eugh, collision on local var :response with controller specs
  let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }
  let(:twiml) { "<Response>expected</Response>" }
  let(:hangup_twiml) {
    <<~EXPECTED
      <?xml version="1.0" encoding="UTF-8"?>
      <Response>
      <Hangup/>
      </Response>
    EXPECTED
  }

  describe "POST#inbound" do
    let(:params) {
      {
        "AccountSid" => account_sid,
        tree_name: :favourite_number,
        "CallSid" => call_sid,
        "Called" => from_number,
        "From" => from_number,
      }
    }

    it "creates the call and calls the operation" do
      expect(Twilio::Rails::Phone::Twiml::GreetingOperation).to receive(:call).with(phone_call_id: phone_call.id + 1, tree: tree).and_return(twiml)
      post :inbound, format: :xml, params: params
      expect(response.body).to eq(twiml)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::CreateOperation).to_not receive(:call)
      post :inbound, format: :xml, params: params.merge("AccountSid" => "invalid")
      expect(response.body).to eq(hangup_twiml)
    end
  end

  describe "POST#outbound" do
    let(:phone_call) { create(:phone_call, :outbound, sid: call_sid) }
    let(:params) {
      {
        "AccountSid" => account_sid,
        tree_name: :favourite_number,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "creates the call and calls the operation" do
      expect(Twilio::Rails::Phone::Twiml::GreetingOperation).to receive(:call).with(phone_call_id: phone_call.id, tree: tree).and_return(twiml)
      post :outbound, format: :xml, params: params
      expect(response.body).to eq(twiml)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::CreateOperation).to_not receive(:call)
      post :outbound, format: :xml, params: params.merge("AccountSid" => "invalid")
      expect(response.body).to eq(hangup_twiml)
    end
  end

  describe "POST#prompt" do
    let(:controller_params) {
      params.merge(
        tree_name: :favourite_number,
        response_id: phone_call_response.id.to_s,
      )
    }
    let(:params) {
      {
        "AccountSid" => account_sid,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "finds the call and calls the operations" do
      expect(Twilio::Rails::Phone::Twiml::PromptOperation).to receive(:call).with(phone_call_id: phone_call.id, tree: tree, response_id: phone_call_response.id).and_return(twiml)
      expect(Twilio::Rails::Phone::UpdateOperation).to receive(:call).with(phone_call_id: phone_call.id, params: params).and_return(phone_call)
      post :prompt, format: :xml, params: controller_params
      expect(response.body).to eq(twiml)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::Twiml::PromptOperation).to_not receive(:call)
      post :prompt, format: :xml, params: controller_params.merge("AccountSid" => "invalid")
      expect(response.body).to eq(hangup_twiml)
    end
  end

  describe "POST#prompt_response" do
    let(:controller_params) {
      params.merge(
        tree_name: :favourite_number,
        response_id: phone_call_response.id.to_s,
      )
    }
    let(:params) {
      {
        "AccountSid" => account_sid,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "finds the call and calls the operations" do
      expect(Twilio::Rails::Phone::Twiml::PromptResponseOperation).to receive(:call).with(
        phone_call_id: phone_call.id,
        tree: tree,
        response_id: phone_call_response.id,
        params: params,
      ).and_return(twiml)
      expect(Twilio::Rails::Phone::UpdateOperation).to receive(:call).with(phone_call_id: phone_call.id, params: params).and_return(phone_call)
      post :prompt_response, format: :xml, params: controller_params
      expect(response.body).to eq(twiml)
    end

    context "with SpeechResult" do
      let(:params) {
        {
          "AccountSid" => account_sid,
          "CallSid" => call_sid,
          "Called" => from_number,
          "SpeechResult" => "What is your favourite number?",
        }
      }

      it "saves the changes to the response if present" do
        expect(Twilio::Rails::Phone::Twiml::PromptResponseOperation).to receive(:call).with(
          phone_call_id: phone_call.id,
          tree: tree,
          response_id: phone_call_response.id,
          params: params,
        ).and_return(twiml)
        expect(Twilio::Rails::Phone::UpdateOperation).to receive(:call).with(phone_call_id: phone_call.id, params: params).and_return(phone_call)
        post :prompt_response, format: :xml, params: controller_params
        expect(response.body).to eq(twiml)
        expect(phone_call_response.reload.transcription).to eq("What is your favourite number?")
      end
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::Twiml::PromptResponseOperation).to_not receive(:call)
      post :prompt_response, format: :xml, params: controller_params.merge("AccountSid" => "invalid")
      expect(response.body).to eq(hangup_twiml)
    end
  end

  describe "POST#timeout" do
    let(:controller_params) {
      params.merge(
        tree_name: :favourite_number,
        response_id: phone_call_response.id.to_s,
      )
    }
    let(:params) {
      {
        "AccountSid" => account_sid,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "finds the call and calls the operation" do
      expect(Twilio::Rails::Phone::Twiml::TimeoutOperation).to receive(:call).with(phone_call_id: phone_call.id, tree: tree, response_id: phone_call_response.id).and_return(twiml)
      expect(Twilio::Rails::Phone::UpdateOperation).to receive(:call).with(phone_call_id: phone_call.id, params: params).and_return(phone_call)
      post :timeout, format: :xml, params: controller_params
      expect(response.body).to eq(twiml)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::Twiml::TimeoutOperation).to_not receive(:call)
      post :timeout, format: :xml, params: controller_params.merge("AccountSid" => "invalid")
      expect(response.body).to eq(hangup_twiml)
    end
  end

  describe "POST#receive_response_recording" do
    let(:controller_params) {
      params.merge(
        response_id: phone_call_response.id.to_s,
      )
    }
    let(:params) {
      {
        "AccountSid" => account_sid,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "finds the call and calls the operation" do
      expect(Twilio::Rails::Phone::ReceiveRecordingOperation).to receive(:call).with(phone_call_id: phone_call.id, response_id: phone_call_response.id, params: params)
      post :receive_response_recording, format: :xml, params: controller_params
      expect(response).to have_http_status(:ok)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::ReceiveRecordingOperation).to_not receive(:call)
      post :receive_response_recording, format: :xml, params: controller_params.merge("AccountSid" => "invalid")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST#status" do
    let(:params) {
      {
        "AccountSid" => account_sid,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "finds the call and calls the operation" do
      expect(Twilio::Rails::Phone::UpdateOperation).to receive(:call).with(phone_call_id: phone_call.id, params: params)
      post :status, format: :xml, params: params
      expect(response).to have_http_status(:ok)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::UpdateOperation).to_not receive(:call)
      post :status, format: :xml, params: params.merge("AccountSid" => "invalid")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST#transcribe" do
    let(:controller_params) {
      params.merge(
        response_id: phone_call_response.id.to_s,
      )
    }
    let(:params) {
      {
        "AccountSid" => account_sid,
        "CallSid" => call_sid,
        "Called" => from_number,
      }
    }

    it "finds the call and calls the operation" do
      expect(Twilio::Rails::Phone::UpdateResponseOperation).to receive(:call).with(phone_call_id: phone_call.id, response_id: phone_call_response.id, params: params)
      post :transcribe, format: :xml, params: controller_params
      expect(response).to have_http_status(:ok)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::Phone::UpdateResponseOperation).to_not receive(:call)
      post :transcribe, format: :xml, params: controller_params.merge("AccountSid" => "invalid")
      expect(response).to have_http_status(:ok)
    end
  end
end
