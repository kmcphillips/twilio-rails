# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::SMS::DelegatedResponder, type: :model do
  let(:conversation) { message.sms_conversation }
  let(:message) { create(:message, :inbound) }
  subject(:responder) { described_class.new(message) }

  describe ".responder_name" do
    it "returns the name of the class" do
      expect(described_class.responder_name).to eq("delegated")
    end
  end

  describe "#initialize" do
    it "sets message and conversation" do
      expect(responder.message).to eq(message)
      expect(responder.sms_conversation).to eq(conversation)
    end
  end

  describe "#reply" do
    it "raises" do
      expect { subject.reply }.to raise_error(NotImplementedError)
    end
  end

  describe "#handle?" do
    it "raises" do
      expect { subject.handle? }.to raise_error(NotImplementedError)
    end
  end

  describe "#matches?" do
    let(:message) { create(:message, :inbound, body: "oh, hello") }

    context "String" do
      it "matches ignoring case" do
        expect(responder.send(:matches?, "OH, HELLO")).to be(true)
      end

      it "matches a substring" do
        expect(responder.send(:matches?, "hello")).to be(true)
      end

      it "does not match" do
        expect(responder.send(:matches?, "hi")).to be(false)
      end
    end

    context "Regexp" do
      it "matches the regexp" do
        expect(responder.send(:matches?, /hel.o/)).to be(true)
      end

      it "does not match" do
        expect(responder.send(:matches?, /hi/)).to be(false)
      end
    end

    context "coersed type" do
      let(:message) { create(:message, :inbound, body: "test_123")}

      it "matches a symbol" do
        expect(responder.send(:matches?, :test)).to be(true)
      end

      it "matches an int" do
        expect(responder.send(:matches?, 123)).to be(true)
      end
    end

    it "raises with somethign else" do
      expect { responder.send(:matches?, Object.new) }.to raise_error(Twilio::Rails::SMS::InvalidResponderError)
    end
  end
end
