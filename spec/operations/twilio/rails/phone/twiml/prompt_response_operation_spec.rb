# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::Twiml::PromptResponseOperation, type: :operation do
  let(:phone_call) { create(:phone_call, tree_name: tree.name) }
  let(:response) { create(:response, phone_call: phone_call) }

  context "with FavouriteNumberTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }
    let(:params) { {"Digits" => "3"} }

    it "outputs twiml" do
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Thank you for your selection.</Say>
        <Redirect>/twilio_mount_location/phone/favourite_number/prompt/#{response.id + 1}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: params, tree: tree)).to eq(expected)
      expect(response.reload.digits).to eq("3")
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
        expect(described_class.call(phone_call_id: phone_call.id, response_id: response.id, params: params, tree: tree)).to eq(expected)
      end
    end
  end
end
