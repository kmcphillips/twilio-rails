# frozen_string_literal: true

RSpec.shared_examples "legacy North American phone numbers" do
  let(:time) { Time.at(1583683053) } # 2020-03-08 11:57:31 -0400
  let(:phone_number) { Twilio::Rails::PhoneNumber.new(number: phone_number_string, country: "CA") }
  let(:phone_number_string) { "+16134445555" }
  let(:object_with_to_s) {
    Class.new do
      def to_s = "1-204-777-8888"
    end.new
  }

  around do |example|
    original_formatter = Twilio::Rails.config.phone_number_formatter
    Twilio::Rails.config.phone_number_formatter = formatter
    example.run
    Twilio::Rails.config.phone_number_formatter = original_formatter
  end

  describe "#coerce" do
    it "is valid exactly correct" do
      expect(subject.coerce("+16134445555")).to eq("+16134445555")
    end

    it "is valid without the plus" do
      expect(subject.coerce("16134445555")).to eq("+16134445555")
    end

    it "is valid with a human formatted number" do
      expect(subject.coerce("1 (613) 444-5555 ")).to eq("+16134445555")
    end

    it "is returns nil when starting with a 1 at wrong digits" do
      expect(subject.coerce("155555")).to be_nil
    end

    it "is returns nil with bad number" do
      expect(subject.coerce("(555) 55-55 ")).to be_nil
    end

    it "returns nil with too few digits" do
      expect(subject.coerce("4445555")).to be_nil
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
      expect(subject.coerce(object_with_to_s)).to eq("+12047778888")
    end
  end

  describe "#valid?" do
    it "checks for strict phone number format" do
      expect(subject.valid?("+12044445555")).to be(true)
    end

    it "is valid with a Twilio::Rails::PhoneNumber object" do
      expect(subject.valid?(phone_number)).to be(true)
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
    it "returns the original when invalid" do
      expect(subject.display("beep")).to be("beep")
    end

    it "returns nil for nil" do
      expect(subject.display(nil)).to be_nil
    end
  end

  describe "#to_param" do
    it "returns nil for invalid number" do
      expect(subject.to_param("66655577")).to eq("")
    end
  end
end
