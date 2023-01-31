# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::AttachRecordingOperation, type: :operation do
  include_examples "twilio phone API call"

  let(:phone_call) { create(:phone_call) }
  let(:recording) { create(:recording, phone_call: phone_call) }
  let(:response) { create(:response, phone_call: phone_call, recording: recording) }

  let(:faraday_response_success) { double(body: "oh, hello", success?: true) }
  let(:faraday_response_failure) { double(body: "oh, hello", success?: false, status: 500) }

  describe "#execute" do
    before do
      response
      allow(Faraday).to receive(:get).with(recording.url).and_return(faraday_response_success)
    end

    it "attaches and calls back" do
      expect(Faraday).to receive(:get).with(recording.url).and_return(faraday_response_success)
      described_class.call(recording_id: recording.id)
      expect(recording.audio.download).to eq("oh, hello")
    end

    it "raises when invalid" do
      expect(Faraday).to receive(:get).with(recording.url).and_return(faraday_response_failure)
      expect {
        described_class.call(recording_id: recording.id)
      }.to raise_error(StandardError)
    end
  end
end
