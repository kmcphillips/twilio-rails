# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::SMS::SendOperation, type: :operation do
  let(:phone_caller) { create(:phone_caller) }
  let(:phone_call) { create(:phone_call, phone_caller: phone_caller) }
  let(:from_number) { "+18884445555" }
  let(:phone_number) { Twilio::Rails::PhoneNumber.new(number: from_number, country: "CA") }
  let(:sms_conversation_class) { ::Twilio::Rails.config.sms_conversation_class }

  describe "#execute" do
    it "creates and sends" do
      phone_call
      expect(Twilio::Rails::Client).to receive(:send_message).twice
        .with(message: anything, to: phone_call.from_number, from: phone_call.number)
        .and_return("a_sid")
      expect {
        described_class.call(phone_caller_id: phone_caller.id, messages: ["a", "b"])
      }.to change { sms_conversation_class.count }.by(1)

      sms_conversation = sms_conversation_class.last
      expect(sms_conversation.number).to eq(phone_call.number)
      expect(sms_conversation.messages.count).to eq(2)
      expect(sms_conversation.messages.first.body).to eq("a")
      expect(sms_conversation.messages.first.sid).to be_present
      expect(sms_conversation.messages.first.direction).to eq("outbound")
    end

    it "creates and sends with from_number as a PhoneNumber" do
      phone_call
      expect(Twilio::Rails::Client).to receive(:send_message)
        .with(message: anything, to: phone_call.from_number, from: phone_number.number)
        .and_return("a_sid")
      expect {
        described_class.call(phone_caller_id: phone_caller.id, from_number: phone_number, messages: ["a"])
      }.to change { sms_conversation_class.count }.by(1)

      sms_conversation = sms_conversation_class.last
      expect(sms_conversation.number).to eq(phone_number.number)
      expect(sms_conversation.messages.count).to eq(1)
      expect(sms_conversation.messages.first.body).to eq("a")
      expect(sms_conversation.messages.first.sid).to be_present
      expect(sms_conversation.messages.first.direction).to eq("outbound")
    end

    it "sends if there is no previous inbound phone call" do
      expect(Twilio::Rails::Client).to receive(:send_message)
        .with(message: anything, to: phone_caller.phone_number, from: from_number)
        .and_return("a_sid")
      expect {
        described_class.call(phone_caller_id: phone_caller.id, from_number: from_number, messages: ["test test"])
      }.to change { sms_conversation_class.count }.by(1)

      sms_conversation = sms_conversation_class.last
      expect(sms_conversation.number).to eq(from_number)
      expect(sms_conversation.messages.count).to eq(1)
      expect(sms_conversation.messages.first.body).to eq("test test")
      expect(sms_conversation.messages.first.sid).to be_present
      expect(sms_conversation.messages.first.direction).to eq("outbound")
    end

    it "raises if trying to send to an invalid from number" do
      expect(Twilio::Rails::Client).to_not receive(:send_message)
      expect {
        described_class.call(phone_caller_id: phone_caller.id, from_number: "234", messages: ["test test"])
      }.to raise_error(Twilio::Rails::SMS::Error)
    end

    it "makes no calls if messages are empty" do
      phone_call
      expect(Twilio::Rails::Client).to receive(:send_message).never
      expect {
        described_class.call(phone_caller_id: phone_caller.id, messages: [])
      }.to_not change { sms_conversation_class.count }
    end

    it "raises with unknown error" do
      phone_call
      expect(Twilio::Rails::Client).to receive(:send_message)
        .with(message: anything, to: phone_call.from_number, from: phone_call.number)
        .and_raise("some error")
      expect {
        described_class.call(phone_caller_id: phone_caller.id, messages: ["a"])
      }.to raise_error(StandardError).and change { sms_conversation_class.count }.by(1).and change { Message.count }.by(0)
    end

    context "twilio response error" do
      let(:twilio_response) { double(status_code: 21610, body: {}) }

      it "handles unsubscribe error" do
        phone_call
        exception = Twilio::REST::RestError.new("Test response", twilio_response)
        expect(Twilio::Rails::Client).to receive(:send_message)
          .with(message: anything, to: phone_call.from_number, from: phone_call.number)
          .and_raise(exception)
        expect {
          described_class.call(phone_caller_id: phone_caller.id, messages: ["a"])
        }.to change { sms_conversation_class.count }.by(1).and change { Message.count }.by(1)
        expect(Message.last.sid).to be_nil
      end
    end
  end
end
