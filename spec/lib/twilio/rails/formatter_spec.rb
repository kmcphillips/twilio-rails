# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Formatter do
  subject(:formatter) { described_class }

  describe "#location" do
    it "handles simple blanks" do
      expect(subject.location(city: "", country: nil, province: "")).to eq("")
    end

    it "handles a single entry" do
      expect(subject.location(city: "Ottawa", country: nil, province: "")).to eq("Ottawa")
    end

    it "handles a complicated place" do
      expect(subject.location(city: "Amsterdam", country: "NL", province: "North Holland")).to eq("Amsterdam, North Holland, NL")
    end

    it "special cases Canada" do
      expect(subject.location(city: "Winnipeg", country: "CA", province: "")).to eq("Winnipeg, Canada")
    end

    it "special cases USA" do
      expect(subject.location(city: "Nashville", country: "US", province: "TN")).to eq("Nashville, TN, USA")
    end
  end
end
