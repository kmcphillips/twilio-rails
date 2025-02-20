# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::SMS::Twiml::MessageOperation, type: :operation do
  include_examples "twilio SMS API call"

  let(:conversation) { message.sms_conversation }
  let(:message) { create(:message) }
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
  it "outputs twiml" do
    responder = double(respond: "oh, hello")
    expect(Twilio::Rails::SMS::Responder).to receive(:new).and_return(responder)
    expected = <<~EXPECTED
      <?xml version="1.0" encoding="UTF-8"?>
      <Response>
      <Message action="/twilio_mount_location/sms/status/#{message.id + 2}">oh, hello</Message>
      </Response>
    EXPECTED
    expect {
      expect(described_class.call(sms_conversation_id: conversation.id, params: params)).to eq(expected)
    }.to change { conversation.messages.count }.by(2)
  end

  it "outputs blank twiml if the reply is blank" do
    responder = double(respond: nil)
    expect(Twilio::Rails::SMS::Responder).to receive(:new).and_return(responder)
    expected = <<~EXPECTED
      <?xml version="1.0" encoding="UTF-8"?>
      <Response/>
    EXPECTED
    expect {
      expect(described_class.call(sms_conversation_id: conversation.id, params: params)).to eq(expected)
    }.to change { conversation.messages.count }.by(1)
  end
end
