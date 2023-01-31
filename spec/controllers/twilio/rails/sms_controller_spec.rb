# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::SMSController, type: :controller do
  include_examples "twilio SMS API call"

  routes { ::Twilio::Rails::Engine.routes }

  let(:conversation) { message.sms_conversation }
  let(:message) { create(:message, :inbound, sid: sms_sid) }
  let(:twiml) { "<Response>expected</Response>" }

  describe "POST#message" do
    let(:params) {
      {
        "AccountSid" => account_sid,
        "ToCountry" => "CA",
        "ToState" => "Montreal",
        "SmsMessageSid" => "SM3333333333333333333333333333",
        "NumMedia" => "0",
        "ToCity" => "",
        "FromZip" => "",
        "SmsSid" => "SMe5555555555555555555555555555555",
        "FromState" => "QC",
        "SmsStatus" => "received",
        "FromCity" => "DRUMMONDVILLE",
        "Body" => "Hello!",
        "FromCountry" => "CA",
        "To" => "+19993332222",
        "ToZip" => "",
        "NumSegments" => "1",
        "MessageSid" => "SMe4444444444444444444444444",
        "From" => "+18887776666",
        "ApiVersion" => "2010-04-01"
      }
    }

    it "creates the session and calls the operation" do
      expect(Twilio::Rails::SMS::Twiml::MessageOperation).to receive(:call).with(sms_conversation_id: conversation.id + 1, params: params).and_return(twiml)
      post :message, format: :xml, params: params, session: {}
      expect(response.body).to eq(twiml)
    end

    it "loads the session and calls the operation" do
      expect(Twilio::Rails::SMS::Twiml::MessageOperation).to receive(:call).with(sms_conversation_id: conversation.id, params: params).and_return(twiml)
      post :message, format: :xml, params: params, session: { sms_conversation_id: conversation.id }
      expect(response.body).to eq(twiml)
    end

    it "renders error without valid account" do
      expected_body = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response/>
      EXPECTED
      expect(Twilio::Rails::SMS::Twiml::MessageOperation).to_not receive(:call)
      post :message, format: :xml, params: { "AccountSid" => "invalid" }, session: { sms_conversation_id: conversation.id }
      expect(response.body).to eq(expected_body)
    end

    context "with a spam filter" do
      around do |example|
        original = Twilio::Rails.config.spam_filter
        Twilio::Rails.config.spam_filter = ->(params) { params["Body"].include?("bad") }
        example.run
        Twilio::Rails.config.spam_filter = original
      end

      it "renders when spam detected" do
        expected_body = <<~EXPECTED
          <?xml version="1.0" encoding="UTF-8"?>
          <Response/>
        EXPECTED
        expect(Twilio::Rails::SMS::Twiml::MessageOperation).to_not receive(:call)
        post :message, format: :xml, params: params.merge("Body" => "bad"), session: { sms_conversation_id: conversation.id }
        expect(response.body).to eq(expected_body)
      end

      it "renders when spam not detected" do
        expect(Twilio::Rails::SMS::Twiml::MessageOperation).to receive(:call).with(sms_conversation_id: conversation.id, params: params).and_return(twiml)
        post :message, format: :xml, params: params, session: { sms_conversation_id: conversation.id }
        expect(response.body).to eq(twiml)
      end
    end
  end

  describe "POST#status" do
    let(:params) {
      {
        "AccountSid" => account_sid,
        "SmsSid" => sms_sid,
      }
    }

    it "finds the call and calls the operation with a message_id" do
      expect(Twilio::Rails::SMS::UpdateMessageOperation).to receive(:call).with(message_id: message.id, params: params)
      post :status, format: :xml, params: params.merge(message_id: message.id)
      expect(response).to have_http_status(:ok)
    end

    it "finds the call and calls the operation with just twilio params" do
      expect(Twilio::Rails::SMS::UpdateMessageOperation).to receive(:call).with(message_id: message.id, params: params)
      post :status, format: :xml, params: params
      expect(response).to have_http_status(:ok)
    end

    it "renders error without valid account" do
      expect(Twilio::Rails::SMS::UpdateMessageOperation).to_not receive(:call)
      post :status, format: :xml, params: params.merge("AccountSid" => "invalid")
      expect(response).to have_http_status(:ok)
    end
  end
end
