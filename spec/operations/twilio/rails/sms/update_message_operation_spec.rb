# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::SMS::UpdateMessageOperation, type: :operation do
  include_examples "twilio SMS API call"

  let(:conversation) { create(:sms_conversation, number: to_number, from_number: from_number) }
  let(:message) { create(:message, sms_conversation: conversation, status: "sent") }
  let(:params) {
    {
      "SmsSid" => sms_sid,
      "SmsStatus" => "delivered",
      "MessageStatus" => "delivered",
      "To" => to_number,
      "MessageSid" => sms_sid,
      "AccountSid" => account_sid,
      "From" => from_number,
      "ApiVersion" => "2010-04-01",
    }
  }

  describe "#execute" do
    it "updates the status if present" do
      described_class.call(message_id: message.id, params: params)
      expect(message.reload.status).to eq("delivered")
    end

    it "does not update if nothing passed in" do
      expect {
        described_class.call(message_id: message.id, params: {})
      }.to_not change { message.reload.attributes }
    end
  end
end
