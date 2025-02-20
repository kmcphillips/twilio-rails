# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::SMS::FindOperation, type: :operation do
  include_examples "twilio SMS API call"

  let(:sms_conversation) { create(:sms_conversation) }

  describe "#execute" do
    it "finds the PhoneCall" do
      sms_conversation
      expect(described_class.call(sms_conversation_id: sms_conversation.id)).to eq(sms_conversation)
    end

    it "returns nil if not found" do
      expect { described_class.call(sms_conversation_id: 3333) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
