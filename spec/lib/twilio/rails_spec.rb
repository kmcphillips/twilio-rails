# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails do
  describe ".config" do
    it "returns the same config object" do
      expect(described_class.config).to be_a(Twilio::Rails::Configuration)
      expect(described_class.config).to eq(described_class.config)
    end
  end

  describe ".deprecator" do
    it "returns the deprecator" do
      expect(described_class.deprecator).to be_a(ActiveSupport::Deprecation)
    end
  end
end
