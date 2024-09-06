# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::Twiml::InvalidPhoneNumberOperation, type: :operation do
  let(:phone_call) { create(:phone_call, tree_name: tree.name) }
  let(:response) { create(:response, phone_call: phone_call) }

  context "with FavouriteNumberTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }
    let(:expected) {
      <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Thank you for calling.</Say>
        <Say voice="male">But you are calling from outside North America.</Say>
        <Hangup/>
        </Response>
      EXPECTED
    }

    it "outputs twiml if the value is set" do
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
    end

    it "accepts a nil phone_call_id" do
      expect(described_class.call(tree: tree)).to eq(expected)
    end
  end

  context "with ToneRatingTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:tone_rating) }
    let(:expected) {
      <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Hangup/>
        </Response>
      EXPECTED
    }

    it "outputs twiml as simply a hangup if no value is set" do
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
    end

    it "accepts a nil phone_call_id" do
      expect(described_class.call(tree: tree)).to eq(expected)
    end
  end
end
