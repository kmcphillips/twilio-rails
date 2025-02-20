# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, type: :model do
  let(:message) { create(:message) }

  it "is valid" do
    expect(message).to be_valid
  end
end
