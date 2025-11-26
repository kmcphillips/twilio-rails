# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::FindOrCreatePhoneCallerOperation, type: :operation do
  let(:phone_caller) { create(:phone_caller) }
  let(:phone_number) { "+16133334444" }

  describe "#execute" do
    it "halts and returns nil if the phone number is invalid" do
      expect(described_class.call(phone_number: "22334455")).to be_nil
    end

    it "halts and returns nil if the phone number is nil" do
      expect(described_class.call(phone_number: nil)).to be_nil
    end

    it "creates when phone caller does not exist" do
      mock_phone_number_lookup(phone_number, country_code: "CA")
      expect {
        result = described_class.call(phone_number: phone_number)
        expect(result).to be_a(PhoneCaller)
        expect(result).to_not be_new_record
        expect(result).to be_previously_new_record
      }.to change { PhoneCaller.count }.by(1)
    end

    it "updates the country code when the phone caller exists" do
      phone_caller.update!(country_code: nil)
      mock_phone_number_lookup(phone_caller.phone_number, country_code: "CA")
      expect {
        result = described_class.call(phone_number: phone_caller.phone_number)
        expect(result).to be_a(PhoneCaller)
        expect(result).to_not be_new_record
        expect(result).to_not be_previously_new_record
        expect(result.country_code).to eq("CA")
      }.to_not change { PhoneCaller.count }
    end

    it "does not try to update the country code if it is already set" do
      mock_phone_number_lookup(phone_caller.phone_number, country_code: "US")
      expect {
        result = described_class.call(phone_number: phone_caller.phone_number)
        expect(result).to be_a(PhoneCaller)
        expect(result.country_code).to eq("CA")
      }.to_not change { PhoneCaller.count }
    end

    it "finds when the phone caller exists" do
      phone_caller
      mock_phone_number_lookup(phone_caller.phone_number, country_code: "CA")
      expect {
        result = described_class.call(phone_number: phone_caller.phone_number)
        expect(result).to be_a(PhoneCaller)
        expect(result).to_not be_new_record
        expect(result).to_not be_previously_new_record
      }.to_not change { PhoneCaller.count }
    end

    it "leaves the country code blank if Twilio REST API returns a 20404 error" do
      mock_phone_number_lookup_error(phone_number, error: Twilio::REST::RestError.new("Not Found", double(body: {}, status_code: 20404)))
      result = described_class.call(phone_number: phone_number)
      expect(result).to be_a(PhoneCaller)
      expect(result.country_code).to be_blank
    end

    it "leaves the country code blank if Twilio REST API returns a non-20404 error" do
      mock_phone_number_lookup_error(phone_number)
      result = described_class.call(phone_number: phone_number)
      expect(result).to be_a(PhoneCaller)
      expect(result.country_code).to be_blank
    end

    it "reports an error if an unexpected error occurs" do
      mock_phone_number_lookup_error(phone_number, error: StandardError.new("Unexpected error"))
      expect(::Rails.error).to receive(:report)
      result = described_class.call(phone_number: phone_number)
      expect(result).to be_a(PhoneCaller)
      expect(result.country_code).to be_blank
    end
  end
end
