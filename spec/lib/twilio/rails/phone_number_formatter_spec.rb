# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::PhoneNumberFormatter do
  around do |example|
    original_formatter = Twilio::Rails.config.phone_number_formatter
    Twilio::Rails.config.phone_number_formatter = Class.new do
      def coerce(value) = "coerce:#{value}"

      def valid?(value) = value.present?

      def to_param(value) = "to_param:#{value}"

      def display(value) = "display:#{value}"
    end.new
    example.run
    Twilio::Rails.config.phone_number_formatter = original_formatter
  end

  describe "#coerce" do
    it "delegates to the configured formatter" do
      expect(described_class.coerce("1234567890")).to eq("coerce:1234567890")
    end
  end

  describe "#coerce!" do
    it "delegates to the configured formatter" do
      expect(described_class.coerce!("1234567890")).to eq("coerce:1234567890")
    end

    context "with nil result" do
      before do
        Twilio::Rails.config.phone_number_formatter = Class.new do
          def coerce(value) = nil
        end.new
      end

      it "raises an error if the number is invalid" do
        expect { described_class.coerce!("5555") }.to raise_error(Twilio::Rails::PhoneNumberFormatter::Error)
      end
    end
  end

  describe "#valid?" do
    it "delegates to the configured formatter" do
      expect(described_class.valid?("1234567890")).to eq(true)
      expect(described_class.valid?(nil)).to eq(false)
    end
  end

  describe "#to_param" do
    it "delegates to the configured formatter" do
      expect(described_class.to_param("1234567890")).to eq("to_param:1234567890")
    end
  end

  describe "#display" do
    it "delegates to the configured formatter" do
      expect(described_class.display("1234567890")).to eq("display:1234567890")
    end
  end
end
