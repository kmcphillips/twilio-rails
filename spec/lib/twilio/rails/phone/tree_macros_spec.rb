# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::TreeMacros do
  subject(:macros) { described_class }

  describe "#digit_gather_interruptable" do
    it "returns a hash" do
      expect(macros.digit_gather_interruptable).to be_a(Hash)
    end

    it "allows the timeout to be overridden" do
      expect(macros.digit_gather_interruptable[:timeout]).to eq(6)
      expect(macros.digit_gather_interruptable(timeout: 12)[:timeout]).to eq(12)
      expect(macros.digit_gather_interruptable(timeout: "9")[:timeout]).to eq(9)
      expect(macros.digit_gather_interruptable(timeout: "tomato")[:timeout]).to eq(6)
      expect(macros.digit_gather_interruptable(timeout: 0)[:timeout]).to eq(6)
    end
  end

  describe "#digits" do
    it "parses out the digits" do
      expect(macros.digits("")).to eq("")
      expect(macros.digits(nil)).to eq("")
      expect(macros.digits("123")).to eq("1, 2, 3")
    end
  end

  describe "#pause" do
    it "returns a pause hash" do
      expect(macros.pause).to eq({pause: 1})
      expect(macros.pause(2)).to eq({pause: 2})
    end
  end

  describe "#numbered_choices" do
    it "lists numbered choices" do
      expect(macros.numbered_choices(["a", "b", "c"])).to eq("For a, press 1. For b, press 2. For c, press 3.")
    end

    it "lists choices with a prefix" do
      expect(macros.numbered_choices(["cat", "bird"], prefix: "As a")).to eq("As a cat, press 1. As a bird, press 2.")
    end

    it "raises with an empty array" do
      expect { macros.numbered_choices([]) }.to raise_error(Twilio::Rails::Phone::Error)
    end

    it "raises with an array that is too big" do
      expect { macros.numbered_choices(10.times.map { "x" }) }.to raise_error(Twilio::Rails::Phone::Error)
    end
  end

  describe "#numbered_choice_response_includes" do
    let(:response) { double(integer_digits: 3) }
    let(:choices) { ["a", "b", "c", "d"] }

    it "returns false if no digit" do
      response = double(integer_digits: nil)
      expect(macros.numbered_choice_response_includes?(choices, response: response)).to eq(false)
    end

    it "returns true if it's in range" do
      expect(macros.numbered_choice_response_includes?(choices, response: response)).to eq(true)
    end

    it "returns false if out of range" do
      response = double(integer_digits: 6)
      expect(macros.numbered_choice_response_includes?(choices, response: response)).to eq(false)
    end

    it "raises if the array is empty" do
      expect { macros.numbered_choice_response_includes?([], response: response) }.to raise_error(Twilio::Rails::Phone::Error)
    end

    it "raises if the array is too big" do
      expect { macros.numbered_choice_response_includes?(10.times.map { "x" }, response: response) }.to raise_error(Twilio::Rails::Phone::Error)
    end
  end

  describe "#answers_yes" do
    it "is mapped to the config" do
      expect(macros.answers_yes).to eq(Twilio::Rails.config.yes_responses)
    end
  end

  describe "#answer_yes?" do
    it "is true if the response is in the yes responses" do
      expect(macros.answer_yes?("Yes please!")).to eq(true)
      expect(macros.answer_yes?("Yes, please!")).to eq(true)
      expect(macros.answer_yes?("YES")).to eq(true)
      expect(macros.answer_yes?(" true ")).to eq(true)
      expect(macros.answer_yes?("yup")).to eq(true)
    end
  end

  describe "#answers_no" do
    it "is mapped to the config" do
      expect(macros.answers_no).to eq(Twilio::Rails.config.no_responses)
    end
  end

  describe "#answer_no?" do
    it "is false if the response is in the no responses" do
      expect(macros.answer_no?("No thank you!")).to eq(true)
      expect(macros.answer_no?("No, thank you!")).to eq(true)
      expect(macros.answer_no?("NO")).to eq(true)
      expect(macros.answer_no?(" false ")).to eq(true)
      expect(macros.answer_no?("nope")).to eq(true)
    end

    it "is false if blank" do
      expect(macros.answer_no?("")).to eq(false)
      expect(macros.answer_no?(nil)).to eq(false)
    end
  end

  describe "#public_file" do
    it "returns the url for the public file" do
      expect(macros.public_file("A440.wav")).to eq("https://example.com/A440.wav")
    end

    it "raises if the file doesn't exist" do
      expect {
        macros.public_file("beep.wav")
      }.to raise_error(Twilio::Rails::Phone::Error)
    end
  end

  describe "#play_public_file" do
    it "delegates to #public_file and returns a hash" do
      expect(macros.play_public_file("A440.wav")).to eq({play: "https://example.com/A440.wav"})
    end

    it "raises if the file doesn't exist" do
      expect {
        macros.play_public_file("beep.wav")
      }.to raise_error(Twilio::Rails::Phone::Error)
    end
  end

  describe "#say" do
    it "returns a Twilio::Rails::Phone::Tree::Message node with the block" do
      # This is pulled from the twilio docs, but their docs are out of date so this needed to be changed to match.
      response = macros.say do |say|
        say.break(strength: "x-weak", time: "100ms")
        say.emphasis(words: "Words to emphasize", level: "moderate")
        say.p(words: "Words to speak")
        say.add_text("aaaaaa")
        say.phoneme("Words to speak", alphabet: "x-sampa", ph: "pɪˈkɑːn")
        say.add_text("bbbbbbb")
        say.prosody(words: "Words to speak", pitch: "-10%", rate: "85%", volume: "-6dB")
        say.s(words: "Words to speak")
        say.say_as("Words to speak", interpretAs: "spell-out")
        say.sub("Words to be substituted", alias: "alias")
        say.w(words: "Words to speak")
      end
      expect(response).to be_a(Twilio::Rails::Phone::Tree::Message)
      expect(response).to be_say
      expect(response.block).to be_present
    end
  end
end
