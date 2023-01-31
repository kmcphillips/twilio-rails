# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::ReceiveRecordingOperation, type: :operation do
  include_examples "twilio phone API call"

  let(:phone_call) { create(:phone_call, number: to_number, from_number: from_number, sid: call_sid) }
  let(:response) { create(:response, phone_call: phone_call, prompt_handle: prompt_handle) }
  let(:recording_sid) { "REdddddddddddddddddddddddddddddddd" }
  let(:recording_url) { "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Recordings/#{recording_sid}" }
  let(:prompt_handle) { "favourite_number" }
  let(:params) {
    {
      "AccountSid" => account_sid,
      "CallSid" => call_sid,
      "RecordingSid" => recording_sid,
      "RecordingUrl" => recording_url,
      "RecordingStatus" => "completed",
      "RecordingDuration" => "2",
      "RecordingChannels" => "1",
      "RecordingSource" => "RecordVerb",
      "RecordingStartTime"=>"Thu, 06 Jun 2019 23:17:34 +0000",
      "ErrorCode" => "0",
    }
  }

  describe "#execute" do
    it "creates the recording and associates the response" do
      recording = nil
      expect {
        recording = described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: params)
      }.to change{ phone_call.reload.recordings.count }.by(1)
      expect(response.reload.recording).to eq(recording)
    end
  end
end
