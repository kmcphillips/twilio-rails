# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "twilio phone API call" do
  let(:account_sid) { "ACaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
  let(:auth_token) { "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" }
  let(:call_sid) { "CA5073183d7484999999999999747bf790" }
  let(:to_number) { "+12048005721" }
  let(:from_number) { "+16135551234" }
end

RSpec.shared_examples "twilio SMS API call" do
  let(:account_sid) { "ACaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
  let(:auth_token) { "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" }
  let(:sms_sid) { "SM5073183d7484999999999999747bf790" }
  let(:to_number) { "+12048005721" }
  let(:from_number) { "+16135551234" }
end
