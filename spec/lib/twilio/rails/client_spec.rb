# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Client, type: :model do
  let(:message) { "Oh, hello" }
  let(:from_number) { Twilio::Rails.config.default_outgoing_phone_number }
  let(:to_number) { "+16666666666" }
  let(:sid) { "SIDaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
  let(:response) { double(sid: sid) }

  describe ".client" do
    it "returns a client" do
      expect(described_class.client).to be_a(Twilio::REST::Client)
    end
  end

  describe ".send_message" do
    it "sends the SMS over the client and returns the sid" do
      expect_any_instance_of(Twilio::REST::Api::V2010::AccountContext::MessageList)
        .to receive(:create)
        .with(
          from: from_number,
          body: message,
          to: to_number,
          status_callback: "https://example.com/twilio_mount_location/sms/status.xml"
        ).and_return(response)
      expect(described_class.send_message(message: message, to: to_number, from: from_number)).to eq(sid)
    end
  end

  describe ".start_call" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }

    it "starts a new phone call to the tree" do
      expect_any_instance_of(Twilio::REST::Api::V2010::AccountContext::CallList)
        .to receive(:create)
        .with(
          from: from_number,
          to: to_number,
          machine_detection: "Enable",
          url: "https://example.com/twilio_mount_location/phone/favourite_number/outbound.xml",
          async_amd: true,
          async_amd_status_callback: "https://example.com/twilio_mount_location/phone/status.xml?async_amd=true",
          async_amd_status_callback_method: "POST",
          status_callback: "https://example.com/twilio_mount_location/phone/status.xml",
          status_callback_event: ["completed", "no-answer"],
          status_callback_method: "POST"
        ).and_return(response)
      expect(described_class.start_call(url: tree.outbound_url, to: to_number, from: from_number)).to eq(sid)
    end

    it "starts a new phone call without answering machine detection" do
      expect_any_instance_of(Twilio::REST::Api::V2010::AccountContext::CallList)
        .to receive(:create)
        .with(
          from: from_number,
          to: to_number,
          machine_detection: "Disable",
          url: "https://example.com/twilio_mount_location/phone/favourite_number/outbound.xml",
          async_amd: true,
          async_amd_status_callback: "https://example.com/twilio_mount_location/phone/status.xml?async_amd=true",
          async_amd_status_callback_method: "POST",
          status_callback: "https://example.com/twilio_mount_location/phone/status.xml",
          status_callback_event: ["completed", "no-answer"],
          status_callback_method: "POST"
        ).and_return(response)
      expect(described_class.start_call(url: tree.outbound_url, to: to_number, from: from_number, answering_machine_detection: false)).to eq(sid)
    end
  end
end
