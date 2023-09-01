# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::CreateOperation, type: :operation do
  include_examples "twilio phone API call"

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
    let(:tree) { Twilio::Rails::Phone::Tree.new("example_tree") }
    let(:phone_caller) { create(:phone_caller, phone_number: from_number) }

    it "creates the PhoneCall" do
      phone_call = described_class.call(params: params, tree: tree)
      expect(phone_call).to be_a(PhoneCall)
    end

    it "creates a call record" do
      expect{ described_class.call(params: params.except("direction"), tree: tree) }.to change{ PhoneCall.count }.by(1)
      phone_call = PhoneCall.last
      expect(phone_call.sid).to eq(call_sid)
      expect(phone_call.number).to eq(to_number)
      expect(phone_call.from_number).to eq(from_number)
      expect(phone_call.from_city).to eq("OTTAWA")
      expect(phone_call.from_province).to eq("ON")
      expect(phone_call.from_country).to eq("CA")
      expect(phone_call.direction).to eq("inbound")
    end

    it "associates the PhoneCaller as a new record" do
      expect {
        described_class.call(params: params, tree: tree)
      }.to change { PhoneCaller.count }.by(1)
    end

    it "attatches an existing phone caller" do
      phone_caller
      expect {
        described_class.call(params: params, tree: tree)
      }.to_not change { PhoneCaller.count }
      phone_call = PhoneCall.last
      expect(phone_call.phone_caller).to eq(phone_caller)
    end

    context "with an invalid phone number" do
      let(:from_number) { "+222333444" }

      it "raises if the phone caller cannot be created" do
        expect(Twilio::Rails).to receive(:notify_exception)
        expect {
          described_class.call(params: params, tree: tree)
        }.to raise_error(Twilio::Rails::Phone::Error)
      end
    end
  end
end
