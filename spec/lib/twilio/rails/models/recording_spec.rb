# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recording, type: :model do
  subject(:recording) { create(:recording) }

  it "is valid" do
    expect(recording).to be_valid
  end

  context "with attachment" do
    subject(:recording) { create(:recording, :audio) }

    it "is valid" do
      expect(recording).to be_valid
      expect(recording.audio).to be_attached
    end
  end

  describe "#length_seconds" do
    it "is nil when blank" do
      recording.update!(duration: nil)
      expect(recording.length_seconds).to be_nil
    end

    it "is an integer" do
      recording.update!(duration: "12")
      expect(recording.length_seconds).to eq(12)
    end
  end
end
