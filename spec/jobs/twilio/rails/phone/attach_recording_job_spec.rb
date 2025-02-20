# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::AttachRecordingJob, type: :job do
  let(:recording) { create(:recording) }

  describe "#perform" do
    it "calls Twilio::Rails::Phone::AttachRecordingOperation" do
      expect(Twilio::Rails::Phone::AttachRecordingOperation).to receive(:call).with(recording_id: recording.id)
      described_class.perform_now(recording_id: recording.id)
    end
  end
end
