# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Twilio::Rails do
  describe ".config" do
    it "returns the same config object" do
      expect(described_class.config).to be_a(Twilio::Rails::Configuration)
      expect(described_class.config).to eq(described_class.config)
    end
  end

  describe ".notify_exception" do
    around do |example|
      previous_exception_notifier = described_class.config.exception_notifier
      example.run
      described_class.config.exception_notifier = previous_exception_notifier
    end

    it "calls if there is a notifier" do
      called = false
      exception = StandardError.new("Oh no")
      described_class.config.exception_notifier = ->(e, m, c, b) {
        called = true
        expect(m).to eq("Oh no")
        expect(e).to eq(exception)
      }
      expect(described_class.notify_exception(exception)).to eq(true)
      expect(called).to be_truthy
    end

    it "does nothing if there is not a notifier" do
      expect(described_class.notify_exception(StandardError.new)).to eq(false)
    end

    it "rescues if the notifier raises" do
      described_class.config.exception_notifier = ->(e, m, c, b) { raise "Oh no" }
      expect(described_class.notify_exception(StandardError.new)).to eq(false)
    end
  end
end
