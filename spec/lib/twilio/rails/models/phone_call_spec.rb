# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PhoneCall, type: :model do
  let(:phone_call) { create(:phone_call, tree_name: "favourite_number") }

  it "is valid" do
    expect(phone_call).to be_valid
  end

  describe ".caller_count_for_tree" do
    let(:phone_caller) { create(:phone_caller) }
    let(:other_phone_caller) { create(:phone_caller, :american_number) }

    it "counts the unique calls for a tree" do
      create(:phone_call, :outbound, :human, phone_caller: other_phone_caller, tree_name: "favourite_number")
      create(:phone_call, :outbound, :human, phone_caller: other_phone_caller, tree_name: "favourite_number")
      create(:phone_call, :outbound, :human, phone_caller: phone_caller, tree_name: "favourite_number")
      expect(PhoneCall.caller_count_for_tree(:favourite_number)).to eq(2)
    end
  end

  context "callbacks" do
    context "unanswered call" do
      let(:phone_call) { create(:phone_call, :outbound, tree_name: "tone_rating") }

      it "does not enqueue when there is no change" do
        phone_call.length_seconds = 123
        phone_call.save!
        expect(Twilio::Rails::Phone::UnansweredJob).to_not have_been_enqueued
      end

      it "does not enqueue when answered by a human" do
        phone_call.answered_by = "human"
        phone_call.save!
        expect(Twilio::Rails::Phone::UnansweredJob).to_not have_been_enqueued
      end

      it "does not enqueue when call is completed" do
        phone_call.call_status = "completed"
        phone_call.save!
        expect(Twilio::Rails::Phone::UnansweredJob).to_not have_been_enqueued
      end

      it "enqueues when answered by a machine" do
        phone_call.answered_by = "machine_start"
        phone_call.save!
        expect(Twilio::Rails::Phone::UnansweredJob).to have_been_enqueued
      end

      it "enqueues when call status is no-answer" do
        phone_call.call_status = "no-answer"
        phone_call.save!
        expect(Twilio::Rails::Phone::UnansweredJob).to have_been_enqueued
      end
    end
  end

  describe "#answering_machine?" do
    it "ignores incoming calls" do
      phone_call = create(:phone_call, :inbound, :answering_machine)
      expect(phone_call).to_not be_answering_machine
    end

    it "returns false for outbound and nil" do
      phone_call = create(:phone_call, :outbound)
      expect(phone_call).to_not be_answering_machine
    end

    it "returns false for outbound and human" do
      phone_call = create(:phone_call, :outbound, :human)
      expect(phone_call).to_not be_answering_machine
    end

    it "knows an outbound machine answered call" do
      phone_call = create(:phone_call, :outbound, :answering_machine)
      expect(phone_call).to be_answering_machine
    end
  end

  describe "#no_answer?" do
    it "ignores incoming calls" do
      phone_call = create(:phone_call, :inbound, :no_answer)
      expect(phone_call).to_not be_no_answer
    end

    it "returns false for outbound and nil" do
      phone_call = create(:phone_call, :outbound)
      expect(phone_call).to_not be_no_answer
    end

    it "returns false for outbound and completed" do
      phone_call = create(:phone_call, :outbound, :completed)
      expect(phone_call).to_not be_no_answer
    end

    it "knows an outbound no answer call" do
      phone_call = create(:phone_call, :outbound, :no_answer)
      expect(phone_call).to be_no_answer
    end

    it "knows an outbound busy call" do
      phone_call = create(:phone_call, :outbound, call_status: "busy")
      expect(phone_call).to be_no_answer
    end

    it "knows an outbound failed call" do
      phone_call = create(:phone_call, :outbound, call_status: "failed")
      expect(phone_call).to be_no_answer
    end
  end

  describe "#location" do
    it "formats the string" do
      expect(phone_call.location).to eq("Ottawa, ON, Canada")
    end
  end

  describe "#recalculate_length" do
    let(:time_seconds) { 1583625751 } # 2020-03-07 19:02:31 -0500

    it "handles no responses" do
      phone_call.recalculate_length
      expect(phone_call.length_seconds).to eq(0)
    end

    it "adds a buffer and handles one response" do
      create(:response, phone_call: phone_call)
      phone_call.reload
      phone_call.recalculate_length
      expect(phone_call.length_seconds).to eq(5)
    end


    it "handles many responses" do
      time = time_seconds
      responses = 5.times.map do |t|
        response = create(:response, phone_call: phone_call)
        response.update!(created_at: Time.at(time))
        time = time + 10
      end

      phone_call.reload
      phone_call.recalculate_length
      expect(phone_call.length_seconds).to eq(45)
    end
  end

  describe "#tree" do
    it "extracts the tree from the tree_name" do
      expect(phone_call.tree).to be_a(Twilio::Rails::Phone::Tree)
      expect(phone_call.tree.name).to eq("favourite_number")
    end
  end

  describe "#for?" do
    it "knows the tree from the name" do
      expect(phone_call.for?(tree: :favourite_number)).to be(true)
      expect(phone_call.for?(tree: :asdf)).to be(false)
    end
  end

  describe "#no_answer?" do
    it "is true for busy" do
      phone_call.update!(direction: "outbound", call_status: "busy")
      expect(phone_call.no_answer?).to be(true)
    end

    it "is true for failed" do
      phone_call.update!(direction: "outbound", call_status: "failed")
      expect(phone_call.no_answer?).to be(true)
    end

    it "is true for no-answer" do
      phone_call.update!(direction: "outbound", call_status: "no-answer")
      expect(phone_call.no_answer?).to be(true)
    end

    it "is false for something else" do
      phone_call.update!(direction: "outbound", call_status: "completed")
      expect(phone_call.no_answer?).to be(false)
    end

    it "is true for busy" do
      phone_call.update!(direction: "outbound", call_status: "busy")
      expect(phone_call.no_answer?).to be(true)
    end

    it "only works for outbound" do
      phone_call.update!(direction: "inbound", call_status: "busy")
      expect(phone_call.no_answer?).to be(false)
    end
  end

  describe "#completed?" do
    it "is completed with the status" do
      expect(PhoneCall.new(call_status: "completed")).to be_completed
    end

    it "is not completed with another status" do
      expect(PhoneCall.new(call_status: "busy")).to_not be_completed
      expect(PhoneCall.new(call_status: "no-answer")).to_not be_completed
    end
  end

  describe "#in_progress?" do
    it "is in progress when blank" do
      expect(PhoneCall.new(call_status: nil)).to be_in_progress
      expect(PhoneCall.new(call_status: "")).to be_in_progress
    end

    it "is in progress when queued" do
      expect(PhoneCall.new(call_status: "queued")).to be_in_progress
    end

    it "is in progress when ringing" do
      expect(PhoneCall.new(call_status: "ringing")).to be_in_progress
    end

    it "is in progress when in-progress" do
      expect(PhoneCall.new(call_status: "in-progress")).to be_in_progress
    end

    it "is in progress when initiated" do
      expect(PhoneCall.new(call_status: "initiated")).to be_in_progress
    end

    it "is not in progress when another status" do
      expect(PhoneCall.new(call_status: "completed")).to_not be_in_progress
    end
  end
end
