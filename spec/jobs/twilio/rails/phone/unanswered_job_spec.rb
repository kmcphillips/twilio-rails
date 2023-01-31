# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::UnansweredJob, type: :job do
  let(:phone_call) { create(:phone_call) }

  describe "#perform" do
    it "calls Twilio::Rails::Phone::UnansweredOperation" do
      expect(Twilio::Rails::Phone::UnansweredOperation).to receive(:call).with(phone_call_id: phone_call.id)
      described_class.perform_now(phone_call_id: phone_call.id)
    end
  end
end
