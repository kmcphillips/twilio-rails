# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::StartCallOperation, type: :operation do
  include_examples "twilio phone API call"

  let(:tree) do
    val = Twilio::Rails::Phone::Tree.new("example_tree")
    val.greeting = Twilio::Rails::Phone::Tree::After.new(:first_message)
    val
  end
  let(:to_number) { "+14445556666" }
  let(:from_number) { Twilio::Rails.config.default_outgoing_phone_number }
  let(:phone_number_object) { Twilio::Rails::PhoneNumber.new(number: "+16667778888", country: "CA") }

  describe "#execute" do
    context "with twilio client success" do
      before do
        expect(Twilio::Rails::Client).to receive(:start_call).and_return(call_sid)
      end

      it "creates the PhoneCall" do
        phone_call = described_class.call(to: to_number, tree: tree)
        expect(phone_call).to be_a(PhoneCall)
      end

      it "creates a call record" do
        expect { described_class.call(to: to_number, tree: tree) }.to change { PhoneCall.count }.by(1)
        phone_call = PhoneCall.last
        expect(phone_call.sid).to eq(call_sid)
        expect(phone_call.number).to eq(from_number)
        expect(phone_call.from_number).to eq(to_number)
        expect(phone_call.direction).to eq("outbound")
      end

      it "creates the call with the override from number as a string" do
        expect { described_class.call(to: to_number, tree: tree, from: "+12345") }.to change { PhoneCall.count }.by(1)
        phone_call = PhoneCall.last
        expect(phone_call.sid).to eq(call_sid)
        expect(phone_call.number).to eq("+12345")
        expect(phone_call.from_number).to eq(to_number)
        expect(phone_call.direction).to eq("outbound")
      end

      it "creates the call with the override from number as a Twilio::Rails::PhoneNumber" do
        expect { described_class.call(to: to_number, tree: tree, from: phone_number_object) }.to change { PhoneCall.count }.by(1)
        phone_call = PhoneCall.last
        expect(phone_call.sid).to eq(call_sid)
        expect(phone_call.number).to eq("+16667778888")
        expect(phone_call.from_number).to eq(to_number)
        expect(phone_call.direction).to eq("outbound")
      end
    end

    context "with twilio client failure" do
      before do
        expect(Twilio::Rails::Client).to receive(:start_call).and_raise(Twilio::REST::TwilioError.new("[HTTP 400] 21216 : Unable to create record
          Account not allowed to call +15555555555
          https://www.twilio.com/docs/errors/21216
          "))
      end

      it "handles an error response from Twilio" do
        expect(::Rails.error).to receive(:report)
        expect {
          described_class.call(to: "+15555555555", tree: tree)
        }.to raise_error(Twilio::REST::TwilioError)
      end
    end
  end
end
