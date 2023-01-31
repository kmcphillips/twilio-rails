# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::FindOperation, type: :operation do
  include_examples "twilio phone API call"

  before do
    phone_call
  end

  let(:phone_call) { create(:phone_call, sid: call_sid) }
  let(:params) {
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
      "FromState" => "ON",
    }
  }

  describe "#execute" do
    it "finds the PhoneCall" do
      expect(described_class.call(params: params)).to eq(phone_call)
    end

    it "raises and does not find" do
      expect { described_class.call(params: {"CallSid" => "asdf"}) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
