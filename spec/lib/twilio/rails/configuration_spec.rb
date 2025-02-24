# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Configuration do
  subject(:config) { described_class.new }

  let(:phone_number) { "+15556667777" }
  let(:account_sid) { "AC123" }
  let(:auth_token) { "auth_token_test" }
  let(:logger) { Logger.new(nil) }
  let(:phone_number_formatter_class) { Twilio::Rails::PhoneNumberFormatters::PhonelibGlobal }

  before do
    config.setup!
    config.default_outgoing_phone_number = phone_number
    config.account_sid = account_sid
    config.auth_token = auth_token
    config.host = "https://test.example.com"
  end

  describe "#initialize" do
    it "creates a blank configuration object" do
      expect(config).to be_a(described_class)
    end

    context "default_outgoing_phone_number" do
      it "sets and gets the value" do
        config.default_outgoing_phone_number = "+15556667777"
        expect(config.default_outgoing_phone_number).to eq(phone_number)
      end
    end

    context "logger" do
      it "defaults to Rails.logger" do
        expect(config.logger).to eq(::Rails.logger)
      end

      it "sets the value" do
        config.logger = logger
        expect(config.logger).to eq(logger)
      end
    end

    context "account_sid" do
      it "sets the value" do
        config.account_sid = account_sid
        expect(config.account_sid).to eq(account_sid)
      end
    end

    context "auth_token" do
      it "sets the value" do
        config.auth_token = auth_token
        expect(config.auth_token).to eq(auth_token)
      end
    end

    context "spam_filter" do
      it "sets the value" do
        spam_filter = ->(params) { false }
        config.spam_filter = spam_filter
        expect(config.spam_filter).to eq(spam_filter)
      end
    end

    context "yes_responses" do
      it "sets the value" do
        yes_responses = ["YES"]
        config.yes_responses = yes_responses
        expect(config.yes_responses).to eq(yes_responses)
      end
    end

    context "no_responses" do
      it "sets the value" do
        no_responses = ["NO"]
        config.no_responses = no_responses
        expect(config.no_responses).to eq(no_responses)
      end
    end

    context "phone_number_formatter" do
      it "defaults to the PhonelibGlobal formatter" do
        expect(config.phone_number_formatter).to be_a(Twilio::Rails::PhoneNumberFormatter::PhonelibGlobal)
      end

      it "is invalid if nil" do
        config.phone_number_formatter = nil
        expect { config.validate! }.to raise_error(Twilio::Rails::Configuration::Error)
      end

      it "can be set to a custom formatter" do
        klass = Class.new
        config.phone_number_formatter = klass.new
        config.validate!
        expect(config.phone_number_formatter).to be_a(klass)
      end
    end

    context "phone_caller_class_name" do
      it "sets the values" do
        expect(config.phone_caller_class_name).to eq("PhoneCaller")
        config.phone_caller_class_name = "OverrideClassName"
        expect(config.phone_caller_class_name).to eq("OverrideClassName")
        expect(config.phone_caller_class).to be_nil
      end
    end

    context "phone_call_class_name" do
      it "sets the values" do
        expect(config.phone_call_class_name).to eq("PhoneCall")
        config.phone_call_class_name = "OverrideClassName"
        expect(config.phone_call_class_name).to eq("OverrideClassName")
        expect(config.phone_call_class).to be_nil
      end
    end

    context "response_class_name" do
      it "sets the values" do
        expect(config.response_class_name).to eq("Response")
        config.response_class_name = "OverrideClassName"
        expect(config.response_class_name).to eq("OverrideClassName")
        expect(config.response_class).to be_nil
      end
    end

    context "sms_conversation_class_name" do
      it "sets the values" do
        expect(config.sms_conversation_class_name).to eq("SMSConversation")
        config.sms_conversation_class_name = "OverrideClassName"
        expect(config.sms_conversation_class_name).to eq("OverrideClassName")
        expect(config.sms_conversation_class).to be_nil
      end
    end

    context "message_class_name" do
      it "sets the values" do
        expect(config.message_class_name).to eq("Message")
        config.message_class_name = "OverrideClassName"
        expect(config.message_class_name).to eq("OverrideClassName")
        expect(config.message_class).to be_nil
      end
    end

    context "recording_class_name" do
      it "sets the values" do
        expect(config.recording_class_name).to eq("Recording")
        config.recording_class_name = "OverrideClassName"
        expect(config.recording_class_name).to eq("OverrideClassName")
        expect(config.recording_class).to be_nil
      end
    end

    context "attach_recordings" do
      it "sets the value" do
        expect(config.attach_recordings).to eq(true)
        config.attach_recordings = "asdf"
        expect(config.attach_recordings).to eq("asdf")
      end
    end
  end

  describe "#include_phone_macros" do
    let(:macro_module) { Module.new }

    it "includes the modules if finalized" do
      config.finalize!
      expect(Twilio::Rails::Phone::TreeMacros.included_modules).to_not include(macro_module)
      config.include_phone_macros(macro_module)
      expect(Twilio::Rails::Phone::TreeMacros.included_modules).to include(macro_module)
    end

    it "includes the modules when finalize! is called" do
      expect(Twilio::Rails::Phone::TreeMacros.included_modules).to_not include(macro_module)
      config.include_phone_macros(macro_module)
      expect(Twilio::Rails::Phone::TreeMacros.included_modules).to_not include(macro_module)
      config.finalize!
      expect(Twilio::Rails::Phone::TreeMacros.included_modules).to include(macro_module)
    end

    it "raises if the argument is not a module" do
      config.include_phone_macros("not a module")

      expect {
        config.finalize!
      }.to raise_error(Twilio::Rails::Configuration::Error)
    end
  end

  describe "#setup!" do
    it "prevents #finalize! and #validate! from being called" do
      config = described_class.new
      config.validate!
      config.finalize!
      expect(config.setup!).to be_nil
      expect { config.validate! }.to raise_error(Twilio::Rails::Configuration::Error)
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)
    end
  end

  describe "#finalize!" do
    it "default_outgoing_phone_number" do
      config.default_outgoing_phone_number = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.default_outgoing_phone_number = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.default_outgoing_phone_number = "222-333-4444"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.default_outgoing_phone_number = phone_number
      expect { config.finalize! }.to_not raise_error
    end

    it "account_sid" do
      config.account_sid = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.account_sid = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.account_sid = account_sid
      expect { config.finalize! }.to_not raise_error
    end

    it "auth_token" do
      config.auth_token = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.auth_token = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.auth_token = auth_token
      expect { config.finalize! }.to_not raise_error
    end

    it "logger" do
      config.logger = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.logger = logger
      expect { config.finalize! }.to_not raise_error
    end

    it "spam_filter" do
      config.spam_filter = nil
      expect { config.finalize! }.to_not raise_error

      config.spam_filter = "something"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.spam_filter = Class.new
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.spam_filter = ->(params) { false }
      expect { config.finalize! }.to_not raise_error
    end

    it "yes_responses" do
      config.yes_responses = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.yes_responses = "something"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.yes_responses = ["YES"]
      expect { config.finalize! }.to_not raise_error
    end

    it "no_responses" do
      config.no_responses = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.no_responses = "something"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.no_responses = ["NO"]
      expect { config.finalize! }.to_not raise_error
    end

    it "phone_caller_class_name" do
      config.phone_caller_class_name = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.phone_caller_class_name = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.phone_caller_class_name = "PhoneCaller"
      expect { config.finalize! }.to_not raise_error
      expect(config.phone_caller_class).to eq(PhoneCaller)
    end

    it "phone_call_class_name" do
      config.phone_call_class_name = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.phone_call_class_name = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.phone_call_class_name = "PhoneCall"
      expect { config.finalize! }.to_not raise_error
      expect(config.phone_call_class).to eq(PhoneCall)
    end

    it "response_class_name" do
      config.response_class_name = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.response_class_name = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.response_class_name = "Response"
      expect { config.finalize! }.to_not raise_error
      expect(config.response_class).to eq(Response)
    end

    it "sms_conversation_class_name" do
      config.sms_conversation_class_name = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.sms_conversation_class_name = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.sms_conversation_class_name = "SMSConversation"
      expect { config.finalize! }.to_not raise_error
      expect(config.sms_conversation_class).to eq(SMSConversation)
    end

    it "message_class_name" do
      config.message_class_name = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.message_class_name = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.message_class_name = "Message"
      expect { config.finalize! }.to_not raise_error
      expect(config.message_class).to eq(Message)
    end

    it "recording_class_name" do
      config.recording_class_name = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.recording_class_name = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.recording_class_name = "Recording"
      expect { config.finalize! }.to_not raise_error
      expect(config.recording_class).to eq(Recording)
    end

    it "controller_http_methods" do
      config.controller_http_methods = nil
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = []
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = ""
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = "POST"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = ["POST"]
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = [:get, :get, :post]
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = [:post, :put]
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.controller_http_methods = [:post, :get]
      expect { config.finalize! }.to_not raise_error

      config.controller_http_methods = [:get, :post]
      expect { config.finalize! }.to_not raise_error

      config.controller_http_methods = [:post]
      expect { config.finalize! }.to_not raise_error

      config.controller_http_methods = [:get]
      expect { config.finalize! }.to_not raise_error
    end
  end

  describe "host" do
    it "defaults to rails config" do
      config.finalize!
      expect(config.host).to eq("https://test.example.com")
      expect(config.host_domain).to eq("test.example.com")
    end

    it "allows an override that includes a port" do
      config.host = "https://example.com:3000"
      config.finalize!
      expect(config.host).to eq("https://example.com:3000")
      expect(config.host_domain).to eq("example.com")
    end

    it "allows an override uses http" do
      config.host = "http://example.com"
      config.finalize!
      expect(config.host).to eq("http://example.com")
      expect(config.host_domain).to eq("example.com")
    end

    it "allows an override and strips trailing slash" do
      config.host = "https://example.com/"
      config.finalize!
      expect(config.host).to eq("https://example.com")
      expect(config.host_domain).to eq("example.com")
    end

    it "raises when an invalid host is set" do
      config.host = "asdf"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)

      config.host = "http://example.com/some/path"
      expect { config.finalize! }.to raise_error(Twilio::Rails::Configuration::Error)
    end
  end

  describe "controller_http_methods" do
    it "defaults to both get and post" do
      config.finalize!
      expect(config.controller_http_methods).to eq([:get, :post])
    end
  end

  describe "#attach_recording?" do
    let(:recording) { create(:recording, duration: 10) }

    it "returns the value as a boolean" do
      expect(config.attach_recording?(recording)).to eq(true)
      config.attach_recordings = true
      expect(config.attach_recording?(recording)).to eq(true)
      config.attach_recordings = "yes"
      expect(config.attach_recording?(recording)).to eq(true)
      config.attach_recordings = false
      expect(config.attach_recording?(recording)).to eq(false)
      config.attach_recordings = nil
      expect(config.attach_recording?(recording)).to eq(false)
    end

    it "returns the proc value as a boolean" do
      config.attach_recordings = ->(recording) { recording.duration == "10" }
      expect(config.attach_recording?(recording)).to eq(true)
      recording.update!(duration: "20")
      expect(config.attach_recording?(recording)).to eq(false)
    end
  end

  describe "phone_trees" do
    it "adds the tree after finalize" do
      config.phone_trees.register(ToneRatingTree)
      expect(config.phone_trees.all.count).to eq(0)
      expect {
        config.finalize!
      }.to change { config.phone_trees.all.count }.by(1)
    end

    it "adds immediately if finalized" do
      config.finalize!
      expect {
        config.phone_trees.register(FavouriteNumberTree)
      }.to change { config.phone_trees.all.count }.by(1)
    end

    it "registers by proc" do
      expect {
        config.phone_trees.register(-> { FavouriteNumberTree })
        config.finalize!
      }.to change { config.phone_trees.all.count }.by(1)
    end

    it "registers by class" do
      expect {
        config.phone_trees.register(ToneRatingTree)
        config.finalize!
      }.to change { config.phone_trees.all.count }.by(1)
    end

    it "registers by class name string" do
      expect {
        config.phone_trees.register("ToneRatingTree")
        config.finalize!
      }.to change { config.phone_trees.all.count }.by(1)
    end

    it "registers by block" do
      expect {
        config.phone_trees.register { "FavouriteNumberTree" }
        config.finalize!
      }.to change { config.phone_trees.all.count }.by(1)
    end

    it "asserts the tree is valid" do
      config.finalize!

      expect { config.phone_trees.register("ConstDoesNotExist") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { config.phone_trees.register(Object.new) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { config.phone_trees.register(Object) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { config.phone_trees.register("") }.to raise_error(Twilio::Rails::Configuration::Error)
      expect { config.phone_trees.register(nil) }.to raise_error(Twilio::Rails::Configuration::Error)
    end

    it "does not allow duplicate registers by name" do
      config.finalize!
      config.phone_trees.register { "FavouriteNumberTree" }

      expect {
        config.phone_trees.register { "FavouriteNumberTree" }
      }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    context "with ToneRatingTree" do
      before do
        config.phone_trees.register(ToneRatingTree)
        config.finalize!
      end

      it "finds by name" do
        expect(config.phone_trees.for("tone_rating")).to eq(ToneRatingTree.tree)
        expect(config.phone_trees.for(:tone_rating)).to eq(ToneRatingTree.tree)
      end

      it "raises if not found by name" do
        expect {
          config.phone_trees.for("asdf")
        }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end

      it "returns a list of all" do
        all = config.phone_trees.all

        expect(all).to be_a(Hash)
        expect(all).to be_frozen
        expect(all.size).to eq(1)
        expect(all.keys).to eq(["tone_rating"])
        expect(all.values).to eq([ToneRatingTree.tree])
      end
    end
  end

  describe "sms_responders" do
    it "adds the responders after finalize" do
      config.sms_responders.register(HelloResponder)
      expect(config.sms_responders.all.count).to eq(0)
      expect {
        config.finalize!
      }.to change { config.sms_responders.all.count }.by(1)
    end

    it "adds immediately if finalized" do
      config.finalize!
      expect {
        config.sms_responders.register(HelloResponder)
      }.to change { config.sms_responders.all.count }.by(1)
    end

    it "registers by proc" do
      expect {
        config.sms_responders.register(-> { HelloResponder })
        config.finalize!
      }.to change { config.sms_responders.all.count }.by(1)
    end

    it "registers by class" do
      expect {
        config.sms_responders.register(HelloResponder)
        config.finalize!
      }.to change { config.sms_responders.all.count }.by(1)
    end

    it "registers by class name string" do
      expect {
        config.sms_responders.register("HelloResponder")
        config.finalize!
      }.to change { config.sms_responders.all.count }.by(1)
    end

    it "registers by block" do
      expect {
        config.sms_responders.register { "HelloResponder" }
        config.finalize!
      }.to change { config.sms_responders.all.count }.by(1)
    end

    it "asserts the responder is valid" do
      config.finalize!

      expect { config.sms_responders.register("ConstDoesNotExist") }.to raise_error(Twilio::Rails::SMS::InvalidResponderError)
      expect { config.sms_responders.register(Object.new) }.to raise_error(Twilio::Rails::SMS::InvalidResponderError)
      expect { config.sms_responders.register("") }.to raise_error(Twilio::Rails::Configuration::Error)
      expect { config.sms_responders.register(nil) }.to raise_error(Twilio::Rails::Configuration::Error)
    end

    it "does not allow duplicate registers by name" do
      config.finalize!
      config.sms_responders.register(HelloResponder)

      expect {
        config.sms_responders.register(HelloResponder)
      }.to raise_error(Twilio::Rails::SMS::InvalidResponderError)
    end

    context "with HelloResponder" do
      before do
        config.finalize!
        config.sms_responders.register(HelloResponder)
      end

      it "finds by name" do
        expect(config.sms_responders.for("hello")).to eq(HelloResponder)
        expect(config.sms_responders.for(:hello)).to eq(HelloResponder)
      end

      it "raises if not found by name" do
        expect {
          config.sms_responders.for("asdf")
        }.to raise_error(Twilio::Rails::SMS::InvalidResponderError)
      end

      it "returns a list of all" do
        all = config.sms_responders.all

        expect(all).to be_a(Hash)
        expect(all).to be_frozen
        expect(all.size).to eq(1)
        expect(all.keys).to eq(["hello"])
        expect(all.values).to eq([HelloResponder])
      end
    end
  end
end
