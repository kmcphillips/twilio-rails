# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::PhoneNumberFormatter::NorthAmerica do
  let(:time) { Time.at(1583683053) } # 2020-03-08 11:57:31 -0400
  let(:phone_number) { Twilio::Rails::PhoneNumber.new(number: phone_number_string, country: "CA") }
  let(:phone_number_string) { "+13334445555" }
  let(:object_with_to_s) {
    Class.new do
      def to_s
        "666-777-8888"
      end
    end.new
  }

  subject(:formatter) { described_class.new }

  describe "#coerce" do
    it "is valid exactly correct" do
      expect(subject.coerce("+13334445555")).to eq("+13334445555")
    end

    it "is valid without the plus" do
      expect(subject.coerce("13334445555")).to eq("+13334445555")
    end

    it "is is valid without the one" do
      expect(subject.coerce("+3334445555")).to eq("+13334445555")
    end

    it "is is valid without the one or plus" do
      expect(subject.coerce("3334445555")).to eq("+13334445555")
    end

    it "is valid with a human formatted number" do
      expect(subject.coerce("(333) 444-5555 ")).to eq("+13334445555")
    end

    it "is returns nil when starting with a 1 at wrong digits" do
      expect(subject.coerce("1223334444")).to be_nil
    end

    it "is returns nil with bad number" do
      expect(subject.coerce("(333) 4446-5555 ")).to be_nil
    end

    it "returns nil with too few digits" do
      expect(subject.coerce("4445555")).to be_nil
    end

    it "returns nil for wrong digits" do
      expect(subject.coerce("+43334445555")).to be_nil
    end

    it "returns nil for nil" do
      expect(subject.coerce(nil)).to be_nil
    end

    it "returns nil for blank" do
      expect(subject.coerce("")).to be_nil
    end

    it "passes through Twilio::Rails::PhoneNumber class" do
      expect(subject.coerce(phone_number)).to eq(phone_number_string)
    end

    it "handles an object which #to_s to a phone number" do
      expect(subject.coerce(object_with_to_s)).to eq("+16667778888")
    end
  end

  describe "#valid?" do
    it "checks for strict phone number format" do
      expect(subject.valid?("+13334445555")).to be(true)
    end

    it "is valid with a Twilio::Rails::PhoneNumber object" do
      expect(subject.valid?(phone_number)).to be(true)
    end

    it "is false without the plus" do
      expect(subject.valid?("13334445555")).to be(false)
    end

    it "is false without the one" do
      expect(subject.valid?("+3334445555")).to be(false)
    end

    it "is false with the wrong digits" do
      expect(subject.valid?("+31618844555")).to be(false)
    end

    it "is false for nil" do
      expect(subject.valid?(nil)).to be(false)
    end

    it "is false for blank" do
      expect(subject.valid?(" ")).to be(false)
    end

    it "is false for garbage" do
      expect(subject.valid?("beep")).to be(false)
    end
  end

  describe "#display" do
    it "formats a valid number" do
      expect(subject.display("+12223334444")).to eq("(222) 333 4444")
    end

    it "returns the original when invalid" do
      expect(subject.display("beep")).to be("beep")
    end

    it "returns a formatted string if passed a Twilio::Rails::PhoneNumber object" do
      expect(subject.display(phone_number)).to eq("(333) 444 5555")
    end

    it "returns a formatted string if passed an object that returns a string" do
      expect(subject.display(object_with_to_s)).to eq("(666) 777 8888")
    end

    it "returns nil for nil" do
      expect(subject.display(nil)).to be_nil
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
      expect(subject.to_param(phone_number)).to eq("333-444-5555")
    end

    it "formats an object responding to #to_s number for URL" do
      expect(subject.to_param(object_with_to_s)).to eq("666-777-8888")
    end
  end
end
