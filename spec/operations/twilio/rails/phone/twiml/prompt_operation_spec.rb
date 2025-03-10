# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::Twiml::PromptOperation, type: :operation do
  let(:phone_call) { create(:phone_call, tree_name: tree.name) }
  let(:response) { create(:response, phone_call: phone_call) }

  context "with FavouriteNumberTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }

    it "outputs twiml for digits" do
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Using the keypad on your touch tone phone...</Say>
        <Pause length="2"/>
        <Say voice="Polly.Joanna">please enter your favourite number.</Say>
        <Gather action="/twilio_mount_location/phone/favourite_number/prompt_response/#{response.id}.xml" actionOnEmptyResult="false" input="dtmf" numDigits="1" timeout="10"/>
        <Redirect>/twilio_mount_location/phone/favourite_number/timeout/#{response.id}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end

    it "outputs the prompt_twiml for voice" do
      response.update(prompt_handle: "favourite_number_reason")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Now, please state after the tone your reason for picking those numbers as your favourites.</Say>
        <Record action="/twilio_mount_location/phone/favourite_number/prompt_response/#{response.id}.xml" maxLength="4" recordingStatusCallback="/twilio_mount_location/phone/receive_recording/#{response.id}" transcribe="true" transcribeCallback="/twilio_mount_location/phone/transcribe/#{response.id}"/>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end

    it "outputs the prompt_twiml for speech" do
      response.update(prompt_handle: "favourite_number_speech")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="male">Can you please state your favourite number after the tone?</Say>
        <Gather action="/twilio_mount_location/phone/favourite_number/prompt_response/#{response.id}.xml" actionOnEmptyResult="true" enhanced="true" input="speech" language="en-CA" profanityFilter="true" speechModel="phone_call" speechTimeout="auto" timeout="5"/>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
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

    it "outputs the prompt_twiml for voice" do
      response.update(prompt_handle: "play_first_tone")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Play>https://example.com/A440.wav</Play>
        <Redirect>/twilio_mount_location/phone/tone_rating/prompt_response/#{response.id}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end

    it "outputs the prompt_twiml for speech" do
      response.update(prompt_handle: "speech_with_defaults")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="female">Please say something</Say>
        <Gather action="/twilio_mount_location/phone/tone_rating/prompt_response/#{response.id}.xml" actionOnEmptyResult="true" enhanced="false" input="speech" language="en-US"/>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end

    it "outputs say and play together" do
      response.update(prompt_handle: "first_tone_feedback")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="female">In remembering this tone:</Say>
        <Play>https://example.com/A440.wav</Play>
        <Say voice="female">On a scale from zero to six, please rate how much you enjoyed this tone</Say>
        <Gather action="/twilio_mount_location/phone/tone_rating/prompt_response/#{response.id}.xml" actionOnEmptyResult="false" finishOnKey="" input="dtmf" numDigits="1" timeout="10"/>
        <Redirect>/twilio_mount_location/phone/tone_rating/timeout/#{response.id}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end

    it "wraps the gather when passed the interrupt flag" do
      response.update(prompt_handle: "interrupt_feedback")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Gather action="/twilio_mount_location/phone/tone_rating/prompt_response/#{response.id}.xml" actionOnEmptyResult="false" input="dtmf" numDigits="2" timeout="20">
        <Say voice="female">first say</Say>
        <Say voice="female">second say</Say>
        <Play>https://example.com/wav.mp3</Play>
        <Say voice="female">third say</Say>
        </Gather>
        <Redirect>/twilio_mount_location/phone/tone_rating/timeout/#{response.id}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end

    it "outputs twiml with SSML block" do
      response.update(prompt_handle: "with_ssml_block")
      expected = <<~EXPECTED
        <?xml version="1.0" encoding="UTF-8"?>
        <Response>
        <Say voice="female"><break strength="x-weak" time="100ms"/><emphasis level="moderate">Words to emphasize</emphasis><p>Words to speak</p>aaaaaa<phoneme alphabet="x-sampa" ph="pɪˈkɑːn">Words to speak</phoneme>bbbbbbb<prosody pitch="-10%" rate="85%" volume="-6dB">Words to speak</prosody><s>Words to speak</s><say-as interpret-as="spell-out">Words to speak</say-as><sub alias="alias">Words to be substituted</sub><w>Words to speak</w></Say>
        <Redirect>/twilio_mount_location/phone/tone_rating/prompt_response/#{response.id}.xml</Redirect>
        </Response>
      EXPECTED
      expect(described_class.call(phone_call_id: phone_call.id, tree: tree, response_id: response.id)).to eq(expected)
    end
  end
end
