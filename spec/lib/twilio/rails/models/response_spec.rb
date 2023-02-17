## frozen_string_literal: true
require 'rails_helper'

RSpec.describe Response, type: :model do
  let(:response) { create(:response, phone_call: phone_call, prompt_handle: prompt) }
  let(:phone_call) { create(:phone_call, tree_name: tree.name) }
  let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }
  let(:prompt) { :second_favourite_number }

  it "is valid" do
    expect(response).to be_valid
  end

  describe "#is?" do
    it "matches tree and prompt" do
      expect(response.is?(tree: "favourite_number", prompt: "second_favourite_number")).to be(true)
    end

    it "matches tree and prompt as symbols" do
      expect(response.is?(tree: :favourite_number, prompt: :second_favourite_number)).to be(true)
    end

    it "matches tree and prompt as Tree class" do
      expect(response.is?(tree: tree, prompt: :second_favourite_number)).to be(true)
    end

    it "matches on an array of prompts" do
      expect(response.is?(tree: [:favourite_number, :other_tree], prompt: :second_favourite_number)).to be(true)
    end

    it "does not match tree" do
      expect(response.is?(tree: :bogus, prompt: :second_favourite_number)).to be(false)
    end

    it "does not match prompt" do
      expect(response.is?(tree: :favourite_number, prompt: :bogus)).to be(false)
    end

    it "matches array of prompts" do
      expect(response.is?(tree: :favourite_number, prompt: [:bleep, :second_favourite_number])).to be(true)
    end
  end

  describe "#from?" do
    it "matches tree and prompt" do
      expect(response.from?(tree: "favourite_number")).to be(true)
    end

    it "matches tree and prompt as symbols" do
      expect(response.from?(tree: :favourite_number)).to be(true)
    end

    it "matches tree and prompt as Tree class" do
      expect(response.from?(tree: tree)).to be(true)
    end
  end

  describe "#integer_digits" do
    it "skips nil" do
      expect(response.integer_digits).to be_nil
    end

    it "skips blank" do
      response.update!(digits: "")
      expect(response.integer_digits).to be_nil
    end

    it "skips #" do
      response.update!(digits: "#")
      expect(response.integer_digits).to be_nil
    end

    it "skips *" do
      response.update!(digits: "*")
      expect(response.integer_digits).to be_nil
    end

    it "parses many digits" do
      response.update!(digits: "554")
      expect(response.integer_digits).to eq(554)
    end

    it "parses one digit" do
      response.update!(digits: "1")
      expect(response.integer_digits).to eq(1)
    end

    it "parses zero" do
      response.update!(digits: "0")
      expect(response.integer_digits).to eq(0)
    end
  end

  describe "#star_pound?" do
    it "is false for nil" do
      expect(response.star_pound?).to be(false)
    end

    it "is false for blank" do
      response.update!(digits: "")
      expect(response.star_pound?).to be(false)
    end

    it "is false for a number" do
      response.update!(digits: "2")
      expect(response.star_pound?).to be(false)
    end

    it "is false for numbers" do
      response.update!(digits: "342")
      expect(response.star_pound?).to be(false)
    end

    it "is false if contains numbers" do
      response.update!(digits: "234#")
      expect(response.star_pound?).to be(false)
    end

    it "is true for #" do
      response.update!(digits: "#")
      expect(response.star_pound?).to be(true)
    end

    it "is true for *" do
      response.update!(digits: "*")
      expect(response.star_pound?).to be(true)
    end

    it "is true for many #" do
      response.update!(digits: "#####")
      expect(response.star_pound?).to be(true)
    end

    it "is true for many *" do
      response.update!(digits: "****")
      expect(response.star_pound?).to be(true)
    end

    it "is true for # * mix" do
      response.update!(digits: "#*#***")
      expect(response.star_pound?).to be(true)
    end

    context "#pound_star? alias" do
      it "is false for a number" do
        response.update!(digits: "2")
        expect(response.pound_star?).to be(false)
      end

      it "is true for *" do
        response.update!(digits: "*")
        expect(response.pound_star?).to be(true)
      end

      it "is true for many #" do
        response.update!(digits: "#####")
        expect(response.pound_star?).to be(true)
      end
    end
  end

  describe "#transcription_matches?" do
    it "returns false if transcription is blank" do
      response.update!(transcription: nil)
      expect(response.transcription_matches?("asdf")).to be(false)
    end

    it "returns true if it matches a string and ignores case" do
      response.update!(transcription: "BBB")
      expect(response.transcription_matches?("aaa", "bbb")).to be(true)
    end

    it "returns false if it does not match a string" do
      response.update!(transcription: "ccc")
      expect(response.transcription_matches?("aaa", "bbb")).to be(false)
    end

    it "returns true and turns symbols into strings" do
      response.update!(transcription: "zz bbbbbb ddd")
      expect(response.transcription_matches?(:aaa, :bbb)).to be(true)
    end

    it "returns true if matches a regex" do
      response.update!(transcription: "a nice day at the beach.")
      expect(response.transcription_matches?(/sun/, /moon/, /day/)).to be(true)
    end

    it "returns false if it does not match a regex" do
      response.update!(transcription: "a nice evening at the beach.")
      expect(response.transcription_matches?(/night/)).to be(false)
    end

    it "unboxes and handles if an array is passed in" do
      response.update!(transcription: "aa bbbbb cc")
      expect(response.transcription_matches?([ "aaa", "bbb" ])).to be(true)
    end

    it "raises if arguments are blank" do
      response.update!(transcription: "mayonaise")
      expect {
        response.transcription_matches?
      }.to raise_error(ArgumentError)
    end

    it "raises if a weird object is passed in" do
      response.update!(transcription: "bbb")
      expect {
        response.transcription_matches?(111)
      }.to raise_error(ArgumentError)
    end
  end

  describe "#answer_yes?" do
    it "is false if no transcription" do
      expect(response).to_not be_answer_yes
    end

    it "is false if answer is no" do
      response.update!(transcription: "no")
      expect(response).to_not be_answer_yes
    end

    it "is true for yes answers" do
      expect(Response.new(transcription: "Yes")).to be_answer_yes
      expect(Response.new(transcription: "accept")).to be_answer_yes
      expect(Response.new(transcription: "true")).to be_answer_yes
    end
  end

  describe "#answer_no?" do
    it "is false if no transcription" do
      expect(response).to_not be_answer_no
    end

    it "is false if answer is yes" do
      response.update!(transcription: "yes")
      expect(response).to_not be_answer_no
    end

    it "is true for no answers" do
      expect(Response.new(transcription: "No")).to be_answer_no
      expect(Response.new(transcription: "decline")).to be_answer_no
      expect(Response.new(transcription: "false")).to be_answer_no
    end
  end

  describe "#first_for_phone_call?" do
    it "knows it is the only response" do
      expect(response.first_for_phone_call?).to be(true)
    end

    it "knows it is not the first one" do
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
      expect(response.first_for_phone_call?).to be(false)
    end

    it "know there are more after" do
      response
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
      expect(response.first_for_phone_call?).to be(true)
    end

    it "ignores other responses" do
      2.times { create(:response, phone_call: phone_call, prompt_handle: :another) }
      response
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
      expect(response.first_for_phone_call?).to be(true)
    end

    it "includes timeouts" do
      timeout_response = create(:response, phone_call: phone_call, prompt_handle: prompt, timeout: true)
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
      expect(timeout_response.first_for_phone_call?).to be(true)
    end

    it "ignores timeouts if flag passed in" do
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt, timeout: true) }
      response
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
      expect(response.first_for_phone_call?(include_timeouts: false)).to be(true)
    end

    it "ignores timeouts if flag passed in" do
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt, timeout: true) }
      response
      2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
      expect(response.first_for_phone_call?(include_timeouts: true)).to be(false)
      expect(response.first_for_phone_call?).to be(false)
    end
  end

  describe "#first_for_phone_caller?" do
    let(:other_phone_call) { create(:phone_call, tree_name: tree.name) }

    context "with one call" do
      it "knows it is the only response" do
        expect(response.first_for_phone_caller?).to be(true)
      end

      it "knows it is not the first one" do
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
        expect(response.first_for_phone_caller?).to be(false)
      end

      it "know there are more after" do
        response
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
        expect(response.first_for_phone_caller?).to be(true)
      end

      it "ignores other responses" do
        2.times { create(:response, phone_call: phone_call, prompt_handle: :another) }
        response
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
        expect(response.first_for_phone_caller?).to be(true)
      end

      it "includes timeouts" do
        timeout_response = create(:response, phone_call: phone_call, prompt_handle: prompt, timeout: true)
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
        expect(timeout_response.first_for_phone_caller?).to be(true)
      end

      it "ignores timeouts if flag passed in" do
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt, timeout: true) }
        response
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
        expect(response.first_for_phone_caller?(include_timeouts: false)).to be(true)
      end

      it "ignores timeouts if flag passed in" do
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt, timeout: true) }
        response
        2.times { create(:response, phone_call: phone_call, prompt_handle: prompt) }
        expect(response.first_for_phone_caller?(include_timeouts: true)).to be(false)
        expect(response.first_for_phone_caller?).to be(false)
      end
    end

    it "knows there was another response on another tree earlier" do
      create(:response, phone_call: other_phone_call, prompt_handle: prompt)
      response
      expect(response.first_for_phone_caller?).to be(false)
    end

    it "ignores later responses on other trees" do
      response
      3.times { create(:response, phone_call: other_phone_call, prompt_handle: prompt) }
      expect(response.first_for_phone_caller?).to be(true)
    end

    it "matches on the tree name too" do
      unmatching_phone_call = create(:phone_call, tree_name: :unmatching)
      create(:response, phone_call: unmatching_phone_call, prompt_handle: prompt)
      response
      expect(response.first_for_phone_caller?).to be(true)
    end
  end
end
