# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::BaseTree, type: :model do
  let(:described_subclass) do
    Class.new(described_class) do
      class << self
        def tree_name
          "described_subclass"
        end
      end
    end
  end

  describe ".tree" do
    it "is a tree with the name" do
      expect(described_subclass.tree).to be_a(Twilio::Rails::Phone::Tree)
      expect(described_subclass.tree.name).to eq("described_subclass")
    end
  end

  describe ".tree_name" do
    it "is the demodulized string" do
      expect(described_class.tree_name).to eq("base")
    end
  end

  describe ".macros" do
    it "has macros as an anonymous module" do
      expect(described_class.macros).to eq(Twilio::Rails::Phone::TreeMacros)
    end
  end

  context "with FavouriteNumberTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:favourite_number) }

    it "sets the name" do
      expect(tree.name).to eq("favourite_number")
    end

    it "sets the configuraton" do
      expect(tree.config[:voice]).to eq("male")
      expect(tree.config[:final_timeout_message][:say]).to eq("Sorry we have lost you.")
    end

    it "sets the greeting" do
      expect(tree.greeting).to be_a(Twilio::Rails::Phone::Tree::After)
      expect(tree.greeting.prompt).to eq(:favourite_number)
    end

    it "sets the prompts" do
      expect(tree.prompts.keys).to eq(["favourite_number", "second_favourite_number", "favourite_number_reason", "favourite_number_speech"])
      expect(tree.prompts.values).to all(be_a(Twilio::Rails::Phone::Tree::Prompt))
    end

    it "loads a gather prompt" do
      prompt = tree.prompts[:second_favourite_number]

      expect(prompt.messages.first.value).to eq("In the case that your favourite number is not available, please enter your second favourite number.")
      expect(prompt.gather.type).to eq(:digits)
      expect(prompt.gather.args).to eq({"number" => 1, "timeout" => 10})
      expect(prompt.after.proc).to be_present
    end

    it "loads a record prompt" do
      prompt = tree.prompts[:favourite_number_reason]

      expect(prompt.messages.call(nil)).to eq("Now, please state after the tone your reason for picking those numbers as your favourites.")
      expect(prompt.gather.type).to eq(:voice)
      expect(prompt.gather.args).to eq({"length" => 4, "profanity_filter" => false, "transcribe" => true})
      expect(prompt.after.hangup?).to be(true)
      expect(prompt.after.messages.first.value).to start_with("Thank you for your input!")
    end

    it "sets the unanswered_prompt" do
      expect(tree.unanswered_call).to be_nil
    end

    it "sets the finished_prompt" do
      expect(tree.finished_call).to be_nil
    end
  end

  context "with ToneRatingTree" do
    let(:tree) { Twilio::Rails.config.phone_trees.for(:tone_rating) }

    it "sets the name" do
      expect(tree.name).to eq("tone_rating")
    end

    it "allows a prompt without a gather" do
      prompt = tree.prompts[:play_first_tone]

      expect(prompt.gather).to be_nil
    end

    it "sets the unanswered_prompt" do
      expect(tree.unanswered_call).to be_a(Proc)
    end

    it "sets the finished_prompt" do
      expect(tree.finished_call).to be_a(Proc)
    end
  end
end
