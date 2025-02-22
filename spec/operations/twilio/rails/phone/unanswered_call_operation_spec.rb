# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::UnansweredCallOperation, type: :operation do
  let(:phone_call) { create(:phone_call, :outbound, tree_name: "tone_rating") }

  describe "#execute" do
    it "does nothing if the call is already marked as unanswered" do
      phone_call.update!(unanswered: true)
      expect_any_instance_of(PhoneCall).to_not receive(:touch)
      described_class.call(phone_call_id: phone_call.id)
      expect(phone_call.reload).to be_unanswered
    end

    it "toggles the unanswered flag but does not call if thee is nothing to call" do
      phone_call.update!(tree_name: "favourite_number")
      described_class.call(phone_call_id: phone_call.id)
      expect(phone_call.reload).to be_unanswered
    end

    it "toggles the unanswered flag and calls the callback" do
      expect_any_instance_of(PhoneCall).to receive(:touch)
      described_class.call(phone_call_id: phone_call.id)
      expect(phone_call.reload).to be_unanswered
    end
  end
end
