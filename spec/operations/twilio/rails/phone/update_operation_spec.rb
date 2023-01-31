# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::UpdateOperation, type: :operation do
  include_examples "twilio phone API call"

  let(:phone_call) { create(:phone_call, :human, :outbound, call_status: "in-progress") }

  let(:params) {
    {
      "Called" => to_number,
      "ToState" => "MB",
      "CallerCountry" => "CA",
      "Direction" => "outbound",
      "CallerState" => "ON",
      "ToZip" => "",
      "CallSid" => call_sid,
      "To" => to_number,
      "CallerZip" => "",
      "ToCountry" => "CA",
      "ApiVersion" => "2010-04-01",
      "CalledZip" => "",
      "CalledCity" => "WINNIPEG",
      "CallStatus" => "in-progress",
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
      "FromState" => "ON",
    }
  }

  describe "#execute" do
    it "updates the call_status if changed" do
      expect(described_class.call(phone_call_id: phone_call.id, params: params.merge("CallStatus" => "completed"))).to eq(phone_call)
      expect(phone_call.reload.call_status).to eq("completed")
    end

    it "does not update the call_status if unchanged" do
      expect(described_class.call(phone_call_id: phone_call.id, params: params)).to eq(phone_call)
      expect(phone_call.reload.call_status).to eq("in-progress")
    end

    it "updates the answered_by if changed" do
      expect(described_class.call(phone_call_id: phone_call.id, params: params.merge("AnsweredBy" => "answering_machine"))).to eq(phone_call)
      expect(phone_call.reload.answered_by).to eq("answering_machine")
    end

    it "does not update the answered_by if unchanged" do
      expect(described_class.call(phone_call_id: phone_call.id, params: params.merge("AnsweredBy" => "human"))).to eq(phone_call)
      expect(phone_call.reload.answered_by).to eq("human")
    end
  end
end
