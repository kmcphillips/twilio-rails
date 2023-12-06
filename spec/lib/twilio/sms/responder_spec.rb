# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::SMS::Responder, type: :model do
  include_examples "twilio SMS API call"

  let(:conversation) { message.sms_conversation }
  let(:message) { create(:message, :inbound) }
  let(:phone_caller) { create(:phone_caller, phone_number: conversation.from_number) }
  let(:stub_responder_class) {
    Class.new do
      def initialize(*) ; end
      def handle? ; true ; end
      def reply ; "Hello to you too!" ; end
    end
  }

  subject(:responder) { described_class.new(message) }

  describe "#initialize" do
    it "sets message and conversation" do
      expect(responder.message).to eq(message)
      expect(responder.sms_conversation).to eq(conversation)
    end
  end

  describe "#respond" do
    it "matches on the hello responder" do
      conversation.update!(number: "+14443337777")
      expect(Twilio::Rails.config.sms_responders).to receive(:all).and_return(stub_responder: stub_responder_class)
      expect(subject.respond).to eq("Hello to you too!")
    end

    it "raises if there is no known project handler" do
      conversation.update!(number: "+14443337777")
      message.update!(body: "test")
      error_message = "No responder found for SMS. message_id=#{ message.id } phone_caller_id= from_number=\"+16135551234\" body=\"test\""
      expect { subject.respond }.to raise_error(Twilio::Rails::SMS::InvalidResponderError, error_message)
    end
  end
end
