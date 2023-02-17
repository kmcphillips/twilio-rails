require 'rails_helper'

RSpec.describe Twilio::Rails::Models::PhoneCaller, type: :model do
  let(:phone_caller) { create(:phone_caller) }
  let(:phone_call) { create(:phone_call, phone_caller: phone_caller, tree_name: :tone_rating) }
  let(:other_phone_call) { create(:phone_call, phone_caller: phone_caller, tree_name: :favourite_number) }
  let(:tree) { Twilio::Rails.config.phone_trees.for(:tone_rating) }

  describe "validations" do
    subject(:phone_caller) { build(:phone_caller) }

    it "is valid" do
      expect(phone_caller).to be_valid
    end

    it "reformats the phone number before save if valid from 9 digits" do
      phone_caller.phone_number = "2223334444"
      expect(phone_caller).to be_valid
      expect(phone_caller.phone_number).to eq("+12223334444")
      expect(phone_caller.valid_north_american_phone_number?).to be(true)
    end

    it "reformats the phone number before save if valid from 10 digits" do
      phone_caller.phone_number = "12223334444"
      expect(phone_caller).to be_valid
      expect(phone_caller.phone_number).to eq("+12223334444")
      expect(phone_caller.valid_north_american_phone_number?).to be(true)
    end

    it "reformats the phone number before save if valid including the plus" do
      phone_caller.phone_number = "+12223334444"
      expect(phone_caller).to be_valid
      expect(phone_caller.phone_number).to eq("+12223334444")
      expect(phone_caller.valid_north_american_phone_number?).to be(true)
    end

    it "reformats the phone number before save if valid including special characters" do
      phone_caller.phone_number = "(222) 333-4444"
      expect(phone_caller).to be_valid
      expect(phone_caller.phone_number).to eq("+12223334444")
      expect(phone_caller.valid_north_american_phone_number?).to be(true)
    end

    it "handles reformatting number with 1" do
      phone_caller.phone_number = "12223334444"
      expect(phone_caller).to be_valid
      expect(phone_caller.phone_number).to eq("+12223334444")
      expect(phone_caller.valid_north_american_phone_number?).to be(true)
    end

    context "with invalid phone number" do
      it "does not reformat before save if invalid" do
        phone_caller.phone_number = "abc 123"
        expect(phone_caller).to be_valid
        expect(phone_caller.phone_number).to eq("abc 123")
        expect(phone_caller.valid_north_american_phone_number?).to be(false)
      end

      it "does not reformat before save if prefixed by a non-one digit" do
        phone_caller.phone_number = "72223334444"
        expect(phone_caller).to be_valid
        expect(phone_caller.phone_number).to eq("72223334444")
        expect(phone_caller.valid_north_american_phone_number?).to be(false)
      end

      it "saves without reformatting 10 digits" do
        phone_caller.phone_number = "3334444"
        expect(phone_caller).to be_valid
        expect(phone_caller.phone_number).to eq("3334444")
        expect(phone_caller.valid_north_american_phone_number?).to be(false)
      end
    end

    it "is invalid when not unique" do
      create(:phone_caller, phone_number: "2223334444")
      phone_caller.phone_number = "+12223334444"
      expect(phone_caller).to_not be_valid
    end
  end

  describe ".for" do
    it "finds with a valid number" do
      expect(PhoneCaller.for(phone_caller.phone_number)).to eq(phone_caller)
    end

    it "does not find with a valid number" do
      expect(PhoneCaller.for("2223334444")).to be_nil
    end

    it "does not find with an invalid number" do
      expect(PhoneCaller.for("2244")).to be_nil
    end
  end

  describe "#sms_conversations" do
    before do
      create(:sms_conversation, from_number: "+13334441123")
    end

    it "finds the conversations" do
      sms_conversation = create(:sms_conversation, from_number: phone_caller.phone_number)
      result = phone_caller.sms_conversations
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to eq([sms_conversation])
    end
  end

  describe "#location" do
    it "delegates to the last phone call" do
      phone_call
      expect(phone_caller.location).to eq("Ottawa, ON, Canada")
    end

    it "handles blank phone call" do
      expect(phone_caller.location).to be_nil
    end
  end

  describe "#inbound_calls_for" do
    before do
      create(:phone_call, :inbound, phone_caller: phone_caller, tree_name: :tone_rating)
      create(:phone_call, :inbound, phone_caller: phone_caller, tree_name: :favourite_number)
      create(:phone_call, :inbound, phone_caller: phone_caller, tree_name: :tone_rating)
      create(:phone_call, :outbound, phone_caller: phone_caller, tree_name: :tone_rating)
      create(:phone_call, :inbound, phone_caller: create(:phone_caller, :another_number), tree_name: :tone_rating)
    end

    it "finds calls by tree name" do
      result = phone_caller.inbound_calls_for(:tone_rating)
      expect(result.length).to eq(2)
      result.each do |phone_call|
        expect(phone_call).to be_inbound
        expect(phone_call.tree_name).to eq("tone_rating")
      end
    end

    it "finds calls by tree" do
      result = phone_caller.inbound_calls_for(tree)
      expect(result.length).to eq(2)
      result.each do |phone_call|
        expect(phone_call).to be_inbound
        expect(phone_call.tree_name).to eq("tone_rating")
      end
    end

    it "returns empty array of nothing found" do
      expect(phone_caller.inbound_calls_for(:invalid)).to eq([])
    end
  end

  describe "#outbound_calls_for" do
    before do
      create(:phone_call, :outbound, phone_caller: phone_caller, tree_name: :tone_rating)
      create(:phone_call, :outbound, phone_caller: phone_caller, tree_name: :favourite_number)
      create(:phone_call, :outbound, phone_caller: phone_caller, tree_name: :tone_rating)
      create(:phone_call, :inbound, phone_caller: phone_caller, tree_name: :tone_rating)
      create(:phone_call, :outbound, phone_caller: create(:phone_caller, :another_number), tree_name: :tone_rating)
    end
    it "finds calls by tree name" do
      result = phone_caller.outbound_calls_for(:tone_rating)
      expect(result.length).to eq(2)
      result.each do |phone_call|
        expect(phone_call).to be_outbound
        expect(phone_call.tree_name).to eq("tone_rating")
      end
    end

    it "finds calls by tree" do
      result = phone_caller.outbound_calls_for(tree)
      expect(result.length).to eq(2)
      result.each do |phone_call|
        expect(phone_call).to be_outbound
        expect(phone_call.tree_name).to eq("tone_rating")
      end
    end

    it "returns empty array of nothing found" do
      expect(phone_caller.outbound_calls_for(:invalid)).to eq([])
    end

  end

  describe "#response_digits" do
    it "finds the digits" do
      create(:response, prompt_handle: :with_digits, digits: "123", phone_call: phone_call)
      expect(phone_caller.response_digits(prompt: :with_digits, tree: :tone_rating)).to eq("123")
    end

    it "finds the digits with a prefixed zero" do
      create(:response, prompt_handle: :with_digits, digits: "0123", phone_call: phone_call)
      expect(phone_caller.response_digits(prompt: :with_digits, tree: :tone_rating)).to eq("0123")
    end

    it "finds the digits with non number characters" do
      create(:response, prompt_handle: :with_digits, digits: "1*2#3", phone_call: phone_call)
      expect(phone_caller.response_digits(prompt: :with_digits, tree: :tone_rating)).to eq("1*2#3")
    end

    it "returns nil if not found" do
      expect(phone_caller.response_digits(prompt: :with_digits, tree: :tone_rating)).to be_nil
    end
  end

  describe "#response_integer_digits" do
    it "finds the digits" do
      create(:response, prompt_handle: :with_digits, digits: "123", phone_call: phone_call)
      expect(phone_caller.response_integer_digits(prompt: :with_digits, tree: :tone_rating)).to eq(123)
    end

    it "finds the digits with a prefixed zero" do
      create(:response, prompt_handle: :with_digits, digits: "0123", phone_call: phone_call)
      expect(phone_caller.response_integer_digits(prompt: :with_digits, tree: :tone_rating)).to eq(123)
    end

    it "finds the digits with non number characters" do
      create(:response, prompt_handle: :with_digits, digits: "1*2#3", phone_call: phone_call)
      expect(phone_caller.response_integer_digits(prompt: :with_digits, tree: :tone_rating)).to be_nil
    end

    it "returns nil if not found" do
      expect(phone_caller.response_integer_digits(prompt: :with_digits, tree: :tone_rating)).to be_nil
    end
  end

  describe "#response_reached?" do
    before do
      create(:response, prompt_handle: :one, phone_call: phone_call)
      create(:response, prompt_handle: :one, phone_call: other_phone_call)
      create(:response, prompt_handle: :two, phone_call: phone_call)
      create(:response, prompt_handle: :three, phone_call: phone_call)
    end

    it "knows the response has been reached or not" do
      expect(phone_caller.response_reached?(prompt: :one, tree: :tone_rating)).to be(true)
      expect(phone_caller.response_reached?(prompt: :one, tree: :favourite_number)).to be(true)
      expect(phone_caller.response_reached?(prompt: :two, tree: :tone_rating)).to be(true)
      expect(phone_caller.response_reached?(prompt: :two, tree: :favourite_number)).to be(false)
      expect(phone_caller.response_reached?(prompt: :three, tree: :tone_rating)).to be(true)
      expect(phone_caller.response_reached?(prompt: :four, tree: :tone_rating)).to be(false)
      expect(phone_caller.response_reached?(prompt: :five, tree: :invalid)).to be(false)
    end
  end

  describe "#response_for" do
    before do
      create(:response, prompt_handle: :one, phone_call: phone_call)
      create(:response, prompt_handle: :one, phone_call: other_phone_call)
      create(:response, prompt_handle: :two, phone_call: phone_call)
      @response_one = create(:response, prompt_handle: :one, phone_call: phone_call)
      @response_three = create(:response, prompt_handle: :three, phone_call: phone_call)
      create(:response, prompt_handle: :three, phone_call: other_phone_call)
    end

    it "returns the response if found" do
      expect(phone_caller.response_for(prompt: :three, tree: :tone_rating)).to eq(@response_three)
    end

    it "returns nil if not found" do
      expect(phone_caller.response_for(prompt: :four, tree: :tone_rating)).to be_nil
      expect(phone_caller.response_for(prompt: :one, tree: :invalid)).to be_nil
    end

    it "returns the most recent if there are many" do
      expect(phone_caller.response_for(prompt: :one, tree: :tone_rating)).to eq(@response_one)
    end
  end
end
