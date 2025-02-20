# frozen_string_literal: true

require "rails_helper"

RSpec.describe SMSConversation, type: :model do
  let(:sms_conversation) { create(:sms_conversation) }

  it "is valid" do
    expect(sms_conversation).to be_valid
  end

  describe "#phone_caller" do
    let(:phone_caller) { create(:phone_caller, phone_number: sms_conversation.from_number) }

    it "finds by number" do
      phone_caller
      expect(sms_conversation.phone_caller).to eq(phone_caller)
    end

    it "returns nil if not found" do
      expect(sms_conversation.phone_caller).to be_nil
    end
  end

  describe "#location" do
    it "formats the string" do
      expect(sms_conversation.location).to eq("Ottawa, ON, Canada")
    end
  end
end
