# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::PhoneNumberFormatter::NorthAmerica do
  subject(:formatter) { described_class.new }

  include_examples "legacy North American phone numbers"

  # This behaviour deviates from the shared examples and documents how this
  # formatter and parser class works differently than the global one upcoming.

  describe "#coerce" do
    it "is is valid without the one" do
      expect(subject.coerce("+6134445555")).to eq("+16134445555")
    end

    it "is is valid without the one or plus" do
      expect(subject.coerce("6134445555")).to eq("+16134445555")
    end

    it "returns nil for wrong digits" do
      expect(subject.coerce("+46134445555")).to be_nil
    end
  end

  describe "#valid?" do
    it "is false without the plus" do
      expect(subject.valid?("16134445555")).to be(false)
    end

    it "is false without the one" do
      expect(subject.valid?("+6134445555")).to be(false)
    end

    it "is false with the wrong digits" do
      expect(subject.valid?("+31618844555")).to be(false)
    end
  end

  describe "#display" do
    it "formats a valid number" do
      expect(subject.display("+12223334444")).to eq("(222) 333 4444")
    end

    it "returns a formatted string if passed a Twilio::Rails::PhoneNumber object" do
      expect(subject.display(phone_number)).to eq("(613) 444 5555")
    end

    it "returns a formatted string if passed an object that returns a string" do
      expect(subject.display(object_with_to_s)).to eq("(204) 777 8888")
    end
  end

  describe "#to_param" do
    it "returns nil for invalid number" do
      expect(subject.to_param("66655577")).to eq("")
    end

    it "formats a valid number for URL" do
      expect(subject.to_param("+12223334444")).to eq("222-333-4444")
    end

    it "formats a Twilio::Rails::PhoneNumber for URL" do
      expect(subject.to_param(phone_number)).to eq("613-444-5555")
    end

    it "formats an object responding to #to_s number for URL" do
      expect(subject.to_param(object_with_to_s)).to eq("204-777-8888")
    end
  end
end
