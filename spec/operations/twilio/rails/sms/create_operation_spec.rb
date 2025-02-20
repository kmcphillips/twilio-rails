# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::SMS::CreateOperation, type: :operation do
  include_examples "twilio SMS API call"

  let(:sms_conversation_class) { ::Twilio::Rails.config.sms_conversation_class }

  let(:params) {
    {
      "ToCountry" => "CA",
      "ToState" => "MB",
      "SmsMessageSid" => sms_sid,
      "NumMedia" => "0",
      "ToCity" => "WINNIPEG",
      "FromZip" => "",
      "SmsSid" => sms_sid,
      "FromState" => "ON",
      "SmsStatus" => "received",
      "FromCity" => "OTTAWA",
      "Body" => "Huh",
      "FromCountry" => "CA",
      "To" => to_number,
      "ToZip" => "",
      "NumSegments" => "1",
      "MessageSid" => sms_sid,
      "AccountSid" => account_sid,
      "From" => from_number,
      "ApiVersion" => "2010-04-01"
    }
  }

  describe "#execute" do
    it "creates the SMSConversation" do
      conversation = described_class.call(params: params)
      expect(conversation).to be_a(sms_conversation_class)
    end

    it "creates a call record" do
      expect {
        described_class.call(params: params)
      }.to change { sms_conversation_class.count }.by(1)
      conversation = sms_conversation_class.last
      expect(conversation.number).to eq(to_number)
      expect(conversation.from_number).to eq(from_number)
      expect(conversation.from_city).to eq("OTTAWA")
      expect(conversation.from_province).to eq("ON")
      expect(conversation.from_country).to eq("CA")
    end
  end
end
