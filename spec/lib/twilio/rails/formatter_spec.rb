# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Formatter do
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

  subject(:formatter) { described_class }

  def deprecated
    expect { yield }.to output(/DEPRECATION WARNING/).to_stderr
  end

  describe "#coerce_to_valid_phone_number" do
    it "is valid exactly correct" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("+13334445555")).to eq("+13334445555")
      }
    end

    it "is valid without the plus" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("13334445555")).to eq("+13334445555")
      }
    end

    it "is is valid without the one" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("+3334445555")).to eq("+13334445555")
      }
    end

    it "is is valid without the one or plus" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("3334445555")).to eq("+13334445555")
      }
    end

    it "is valid with a human formatted number" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("(333) 444-5555 ")).to eq("+13334445555")
      }
    end

    it "is returns nil when starting with a 1 at wrong digits" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("1223334444")).to be_nil
      }
    end

    it "is returns nil with bad number" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("(333) 4446-5555 ")).to be_nil
      }
    end

    it "returns nil with too few digits" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("4445555")).to be_nil
      }
    end

    it "returns nil for wrong digits" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("+43334445555")).to be_nil
      }
    end

    it "returns nil for nil" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number(nil)).to be_nil
      }
    end

    it "returns nil for blank" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number("")).to be_nil
      }
    end

    it "passes through Twilio::Rails::PhoneNumber class" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number(phone_number)).to eq(phone_number_string)
      }
    end

    it "handles an object which #to_s to a phone number" do
      deprecated {
        expect(subject.coerce_to_valid_phone_number(object_with_to_s)).to eq("+16667778888")
      }
    end
  end

  describe "#valid_north_american_phone_number?" do
    it "checks for strict phone number format" do
      deprecated {
        expect(subject.valid_north_american_phone_number?("+13334445555")).to be(true)
      }
    end

    it "is valid with a Twilio::Rails::PhoneNumber object" do
      deprecated {
        expect(subject.valid_north_american_phone_number?(phone_number)).to be(true)
      }
    end

    it "is false without the plus" do
      deprecated {
        expect(subject.valid_north_american_phone_number?("13334445555")).to be(false)
      }
    end

    it "is false without the one" do
      deprecated {
        expect(subject.valid_north_american_phone_number?("+3334445555")).to be(false)
      }
    end

    it "is false with the wrong digits" do
      deprecated {
        expect(subject.valid_north_american_phone_number?("+31618844555")).to be(false)
      }
    end

    it "is false for nil" do
      deprecated {
        expect(subject.valid_north_american_phone_number?(nil)).to be(false)
      }
    end

    it "is false for blank" do
      deprecated {
        expect(subject.valid_north_american_phone_number?(" ")).to be(false)
      }
    end

    it "is false for garbage" do
      deprecated {
        expect(subject.valid_north_american_phone_number?("beep")).to be(false)
      }
    end
  end

  describe "#display_phone_number" do
    it "formats a valid number" do
      deprecated {
        expect(subject.display_phone_number("+12223334444")).to eq("(222) 333 4444")
      }
    end

    it "returns the original when invalid" do
      deprecated {
        expect(subject.display_phone_number("beep")).to be("beep")
      }
    end

    it "returns a formatted string if passed a Twilio::Rails::PhoneNumber object" do
      deprecated {
        expect(subject.display_phone_number(phone_number)).to eq("(333) 444 5555")
      }
    end

    it "returns a formatted string if passed an object that returns a string" do
      deprecated {
        expect(subject.display_phone_number(object_with_to_s)).to eq("(666) 777 8888")
      }
    end

    it "returns nil for nil" do
      deprecated {
        expect(subject.display_phone_number(nil)).to be_nil
      }
    end
  end

  describe "#to_phone_number_url_param" do
    it "returns nil for invalid number" do
      deprecated {
        expect(subject.to_phone_number_url_param("66655577")).to eq("")
      }
    end

    it "formats a valid number for URL" do
      deprecated {
        expect(subject.to_phone_number_url_param("+12223334444")).to eq("222-333-4444")
      }
    end

    it "formats a Twilio::Rails::PhoneNumber for URL" do
      deprecated {
        expect(subject.to_phone_number_url_param(phone_number)).to eq("333-444-5555")
      }
    end

    it "formats an object responding to #to_s number for URL" do
      deprecated {
        expect(subject.to_phone_number_url_param(object_with_to_s)).to eq("666-777-8888")
      }
    end
  end

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
