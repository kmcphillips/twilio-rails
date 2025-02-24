# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::PhoneNumber, type: :model do
  let(:number) { "+15143334444" }
  let(:phone_number) { described_class.new(number: number, country: "CA", label: "Test 1", project: :project1) }

  it "is valid" do
    expect(phone_number).to be_truthy
    expect(phone_number.number).to eq(number)
    expect(phone_number.label).to eq("Test 1")
    expect(phone_number.project).to eq("project1")
  end

  it "coerces the number and country" do
    phone_number = described_class.new(number: "1-514-444-5555", country: "ca")
    expect(phone_number.number).to eq("+15144445555")
    expect(phone_number.country).to eq("CA")
  end

  it "raises if the number is not valid" do
    expect {
      described_class.new(number: "5555", country: "ca")
    }.to raise_error(Twilio::Rails::Phone::Error)
  end

  describe "#to_s" do
    it "formats the string" do
      expect(phone_number.to_s).to eq("Phone number +15143334444 (CA) Test 1 for project1")
    end
  end
end
