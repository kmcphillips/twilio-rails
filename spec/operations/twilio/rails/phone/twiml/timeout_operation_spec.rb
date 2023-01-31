# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails::Phone::Twiml::TimeoutOperation, type: :operation do
  let(:phone_call) { create(:phone_call, tree_name: tree.name) }
  let(:response) { create(:response, phone_call: phone_call, prompt_handle: prompt_handle) }
  let(:prompt_handle) { tree.prompts.keys.first }

  context "with FavouriteNumberTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }

    it "outputs twiml for the final timeout" do
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Sorry we have lost you.</Say>
        <Hangup/>
        </Response>
      EXPECTED

      create(:response, phone_call: phone_call, timeout: true)
      create(:response, phone_call: phone_call, timeout: true)

      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
      expect(response.reload.timeout).to be(true)
    end

    context "answering machine detected" do
      let(:phone_call) { create(:phone_call, :outbound, :answering_machine, tree_name: tree.name) }

      it "outputs the hangup when the call is an answering machine" do
        expected = <<~EXPECTED
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
          <Hangup/>
          </Response>
        EXPECTED
        expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
      end
    end
  end

  context "with ToneRatingTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:tone_rating) }
    let(:prompt_handle) { "first_tone_feedback" }

    it "outputs twiml without a timeout message" do
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="female">Sorry, we didn't get a response.</Say>
        <Redirect>/twilio_mount_location/phone/tone_rating/prompt/#{response.id + 1}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
      expect(response.reload.timeout).to be(true)
    end
  end
end
