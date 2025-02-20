# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::UpdateResponseOperation, type: :operation do
  include_examples "twilio phone API call"

  let(:phone_call) { create(:phone_call, number: to_number, from_number: from_number, sid: call_sid, tree_name: "tone_rating") }
  let(:response) { create(:response, phone_call: phone_call, prompt_handle: prompt_handle) }
  let(:phone_caller) { phone_call.phone_caller }
  let(:prompt_handle) { "first_tone_feedback" }
  let(:base_params) {
    {
      "Called" => to_number,
      "ToState" => "MB",
      "CallerCountry" => "CA",
      "Direction" => "inbound",
      "CallerState" => "ON",
      "ToZip" => "",
      "CallSid" => call_sid,
      "To" => to_number,
      "CallerZip" => "",
      "ToCountry" => "CA",
      "ApiVersion" => "2010-04-01",
      "CalledZip" => "",
      "CalledCity" => "WINNIPEG",
      "CallStatus" => "ringing",
      "From" => from_number,
      "AccountSid" => account_sid,
      "CalledCountry" => "CA",
      "CallerCity" => "OTTAWA",
      "Caller" => from_number,
      "FromCountry" => "CA",
      "ToCity" => "WINNIPEG",
      "FromCity" => "OTTAWA",
      "CalledState" => "MB",
      "FromZip" => "",
      "FromState" => "ON"
    }
  }
  let(:digit_params) { base_params.merge("Digits" => "3") }
  let(:transcription_params) { base_params.merge("TranscriptionText" => "hello", "TranscriptionStatus" => "completed") }
  let(:speech_params) { base_params.merge("SpeechResult" => "smart toaster") }

  describe "#execute" do
    before do
      response
      phone_call
    end

    it "updates the digits if present" do
      described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: digit_params)
      expect(response.reload.digits).to eq("3")
    end

    it "updates the transcription if completed and present" do
      described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: transcription_params)
      expect(response.reload.transcription).to eq("hello")
      expect(response.transcribed?).to be(true)
    end

    it "updates the transcription from speech if present" do
      described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: speech_params)
      expect(response.reload.transcription).to eq("smart toaster")
      expect(response.transcribed?).to be(true)
    end

    it "does not update if nothing passed in" do
      expect {
        described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: base_params)
      }.to_not change { response.reload.attributes }
    end
  end
end
