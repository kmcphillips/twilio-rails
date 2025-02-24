# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::Twiml::GreetingOperation, type: :operation do
  let(:phone_call) { create(:phone_call, tree_name: tree.name) }
  let(:response) { create(:response, phone_call: phone_call) }

  context "with FavouriteNumberTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }

    it "outputs twiml" do
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Hello, and thank you for calling!</Say>
        <Redirect>/twilio_mount_location/phone/favourite_number/prompt/#{response.id + 1}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
    end

    context "with international phone number" do
      let(:phone_call) { create(:phone_call, :inbound, :international_number, tree_name: tree.name) }

      it "outputs twiml and supports an international number" do
        expected = <<~EXPECTED
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
          <Say voice="male">Hello, and thank you for calling!</Say>
          <Redirect>/twilio_mount_location/phone/favourite_number/prompt/#{response.id + 1}.xml</Redirect>
          </Response>
        EXPECTED
        expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
      end
    end

    context "with invalid phone number" do
      let(:phone_call) { create(:phone_call, :inbound, :invalid_number, tree_name: tree.name) }

      it "outputs twiml for error" do
        expected = <<~EXPECTED
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
          <Say voice="male">Thank you for calling.</Say>
          <Say voice="male">But you are calling from outside North America.</Say>
          <Hangup/>
          </Response>
        EXPECTED
        expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
      end
    end

    context "with invalid phone number" do
      let(:phone_call) { create(:phone_call, :inbound, :invalid_number, tree_name: tree.name) }

      it "outputs twiml for error" do
        expected = <<~EXPECTED
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
          <Say voice="male">Thank you for calling.</Say>
          <Say voice="male">But you are calling from outside North America.</Say>
          <Hangup/>
          </Response>
        EXPECTED
        expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
      end
    end
  end

  context "with ToneRatingTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:tone_rating) }

    it "outputs twiml" do
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="female">Hello. Please listen to the following tone:</Say>
        <Redirect>/twilio_mount_location/phone/tone_rating/prompt/#{response.id + 1}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
    end

    context "with invalid phone number" do
      let(:phone_call) { create(:phone_call, :inbound, :invalid_number, tree_name: tree.name) }

      it "outputs twiml if no error is set" do
        expected = <<~EXPECTED
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
          <Say voice="female">Hello. Please listen to the following tone:</Say>
          <Redirect>/twilio_mount_location/phone/tone_rating/prompt/#{response.id + 1}.xml</Redirect>
          </Response>
        EXPECTED
        expect(described_class.call(phone_call_id: phone_call.id, tree: tree)).to eq(expected)
      end
    end
  end
end
