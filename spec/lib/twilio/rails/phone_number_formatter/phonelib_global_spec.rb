# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::PhoneNumberFormatter::PhonelibGlobal do
  let(:phone_numbers) do
    {
      canada: "1 (613) 555-1234",
      germany: "+49-30-1234567",
      usa: "+1 213 621 0002 ; 1234", # strips extension
      uk: "+44 20 8759 9036",
      australia: "61-285038000",
      nz: "+64 9 887 5555",
      france: "(33) 74 57 18 555"
    }
  end

  include_examples "legacy North American phone numbers"

  subject(:formatter) { described_class.new }

  describe "#coerce" do
    it "converts for Canada" do
      expect(formatter.coerce(phone_numbers[:canada])).to eq("+16135551234")
    end

    it "converts for Germany" do
      expect(formatter.coerce(phone_numbers[:germany])).to eq("+49301234567")
    end

    it "converts for USA" do
      expect(formatter.coerce(phone_numbers[:usa])).to eq("+12136210002")
    end

    it "converts for UK" do
      expect(formatter.coerce(phone_numbers[:uk])).to eq("+442087599036")
    end

    it "converts for Australia" do
      expect(formatter.coerce(phone_numbers[:australia])).to eq("+61285038000")
    end

    it "converts for New Zealand" do
      expect(formatter.coerce(phone_numbers[:nz])).to eq("+6498875555")
    end

    it "converts for France" do
      expect(formatter.coerce(phone_numbers[:france])).to eq("+33745718555")
    end

    it "returns nil for nil" do
      expect(formatter.coerce(nil)).to be_nil
    end

    it "returns nil for blank" do
      expect(formatter.coerce("")).to be_nil
    end

    it "returns nil for garbage" do
      expect(formatter.coerce("beep")).to be_nil
    end

    it "returns nil for invalid numbers" do
      expect(formatter.coerce("55555")).to be_nil
    end
  end

  describe "#valid?" do
    it "all valid numbers are valid" do
      phone_numbers.each do |country, number|
        expect(formatter.valid?(number)).to be_truthy, "Expected #{number} to be valid for #{country}"
      end
    end

    it "invalid numbers are invalid" do
      expect(formatter.valid?("123")).to be_falsey
      expect(formatter.valid?("")).to be_falsey
      expect(formatter.valid?("potato")).to be_falsey
      expect(formatter.valid?("123&*($%#^#$%34)")).to be_falsey
    end
  end

  describe "#display" do
    it "displays for UK" do
      expect(formatter.display(phone_numbers[:uk])).to eq("+44 20 8759 9036")
    end

    it "displays for Australia" do
      expect(formatter.display(phone_numbers[:australia])).to eq("+61 2 8503 8000")
    end

    it "displays for New Zealand" do
      expect(formatter.display(phone_numbers[:nz])).to eq("+64 9 887 5555")
    end

    it "displays for France" do
      expect(formatter.display(phone_numbers[:france])).to eq("+33 7 45 71 85 55")
    end

    it "displays for Germany" do
      expect(formatter.display(phone_numbers[:germany])).to eq("+49 30 1234567")
    end

    it "displays for Canada" do
      expect(formatter.display(phone_numbers[:canada])).to eq("+1 (613) 555-1234")
    end

    it "displays for USA" do
      expect(formatter.display(phone_numbers[:usa])).to eq("+1 (213) 621-0002")
    end
  end

  describe "#to_param" do
    it "converts all valid numbers" do
      phone_numbers.each do |country, number|
        expect(formatter.to_param(number)).to match(/\A[0-9-]+\z/)
      end
    end

    it "strips leading + from the number" do
      expect(formatter.to_param("+1 213 621 0002")).to eq("1-213-621-0002")
    end

    it "returns an empty string for invalid numbers" do
      expect(formatter.to_param("123")).to eq("")
      expect(formatter.to_param("")).to eq("")
      expect(formatter.to_param("potato")).to eq("")
    end

    it "displays for UK" do
      expect(formatter.to_param(phone_numbers[:uk])).to eq("442087599036")
    end

    it "displays for Australia" do
      expect(formatter.to_param(phone_numbers[:australia])).to eq("61285038000")
    end

    it "displays for New Zealand" do
      expect(formatter.to_param(phone_numbers[:nz])).to eq("6498875555")
    end

    it "displays for France" do
      expect(formatter.to_param(phone_numbers[:france])).to eq("33745718555")
    end

    it "displays for Germany" do
      expect(formatter.to_param(phone_numbers[:germany])).to eq("49301234567")
    end

    it "displays for Canada" do
      expect(formatter.to_param(phone_numbers[:canada])).to eq("1-613-555-1234")
    end

    it "displays for USA" do
      expect(formatter.to_param(phone_numbers[:usa])).to eq("1-213-621-0002")
    end

    it "formats a Twilio::Rails::PhoneNumber" do
      expect(
        subject.to_param(Twilio::Rails::PhoneNumber.new(number: phone_numbers[:france], country: "FR"))
      ).to eq("33745718555")

      expect(
        subject.to_param(Twilio::Rails::PhoneNumber.new(number: phone_numbers[:canada], country: "CA"))
      ).to eq("1-613-555-1234")
    end

    it "formats an object responding to #to_s number for URL" do
      object = Class.new do
        def to_s = "+12047778888"
      end.new
      expect(subject.to_param(object)).to eq("1-204-777-8888")
    end
  end
end
