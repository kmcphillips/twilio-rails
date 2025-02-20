# frozen_string_literal: true

require "rails_helper"

RSpec.describe Twilio::Rails::Phone::Tree, type: :model do
  subject(:tree) { described_class.new(:example) }

  describe "#initialize" do
    it "sets a config with defaults" do
      expect(tree.config).to eq({"voice" => "male", "final_timeout_message" => "Goodbye.", "final_timeout_attempts" => 3})
    end
  end

  describe "#outbound_url" do
    it "should create from the tree and the env" do
      expect(tree.outbound_url).to eq("https://example.com/twilio_mount_location/phone/example/outbound.xml")
    end
  end

  describe "#inbound_url" do
    it "should create from the tree and the env" do
      expect(tree.inbound_url).to eq("https://example.com/twilio_mount_location/phone/example/inbound.xml")
    end
  end

  describe Twilio::Rails::Phone::Tree::Prompt, type: :model do
    describe "#initialize" do
      let(:valid_attributes) { {name: "asdf", message: "hello", gather: {type: :digits}, after: :hangup} }

      it "sets the gather" do
        expect(described_class.new(**valid_attributes).gather).to be_a(Twilio::Rails::Phone::Tree::Gather)
      end

      it "sets the after" do
        expect(described_class.new(**valid_attributes).after).to be_a(Twilio::Rails::Phone::Tree::After)
      end

      it "sets the message" do
        value = described_class.new(**valid_attributes)
        expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
        expect(value.messages.length).to eq(1)
        expect(value.messages.first.say?).to be_truthy
        expect(value.messages.first.value).to eq("hello")
      end

      it "raises if message is something weird" do
        expect { described_class.new(**valid_attributes.merge(message: Object.new)) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end

      it "sets the prompt name" do
        expect(described_class.new(**valid_attributes).name).to eq(:asdf)
      end

      it "raises if prompt name is not set" do
        expect { described_class.new(**valid_attributes.merge(name: nil)) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end

      it "lets message: be a proc" do
        value = described_class.new(**valid_attributes.merge(message: proc {}))
        expect(value.messages).to be_a(Proc)
      end

      it "lets message: be a play" do
        value = described_class.new(**valid_attributes.merge(message: {play: "https://example.com/play.wav"}))
        expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
        expect(value.messages.length).to eq(1)
        expect(value.messages.first.play?).to be_truthy
        expect(value.messages.first.value).to eq("https://example.com/play.wav")
      end

      it "lets the message: be a say" do
        value = described_class.new(**valid_attributes.merge(message: {say: "hello"}))
        expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
        expect(value.messages.length).to eq(1)
        expect(value.messages.first.say?).to be_truthy
        expect(value.messages.first.value).to eq("hello")
      end

      it "allows gather: to be nil" do
        expect(described_class.new(**valid_attributes.merge(gather: nil)).gather).to be_nil
      end
    end
  end

  describe Twilio::Rails::Phone::Tree::After, type: :model do
    describe "#initialize" do
      context "accepts a hash" do
        it "with a prompt as string" do
          expect(described_class.new("prompt" => "abc").prompt).to eq(:abc)
        end

        it "with a prompt as symbol" do
          expect(described_class.new(prompt: :abc).prompt).to eq(:abc)
        end

        it "with hangup" do
          expect(described_class.new(hangup: true).hangup?).to be true
        end

        it "with hangup as something" do
          expect(described_class.new("hangup" => "yes").hangup?).to be true
        end

        it "with hangup as something" do
          expect(described_class.new(prompt: :abc).hangup?).to be false
        end

        it "raises without prompt or hangup" do
          expect { described_class.new({}) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
        end

        it "raises with prompt and hangup" do
          expect { described_class.new(prompt: :abc, hangup: true) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
        end

        it "sets the message" do
          value = described_class.new(message: "hello", prompt: :asdf)
          expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
          expect(value.messages.length).to eq(1)
          expect(value.messages.first.say?).to be_truthy
          expect(value.messages.first.value).to eq("hello")
        end

        it "sets the play" do
          value = described_class.new(message: {play: "https://example.com/play.wav"}, hangup: true)
          expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
          expect(value.messages.length).to eq(1)
          expect(value.messages.first.play?).to be_truthy
          expect(value.messages.first.value).to eq("https://example.com/play.wav")
        end

        it "sets the say" do
          value = described_class.new(message: {say: "hello", voice: "julie"}, hangup: true)
          expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
          expect(value.messages.length).to eq(1)
          expect(value.messages.first.say?).to be_truthy
          expect(value.messages.first.value).to eq("hello")
          expect(value.messages.first.voice).to eq("julie")
        end

        it "lets say: be a proc" do
          value = described_class.new(message: {say: proc {}}, hangup: true)
          expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
          expect(value.messages.length).to eq(1)
        end

        it "lets play: be a proc" do
          value = described_class.new(message: {play: proc {}}, hangup: true)
          expect(value.messages).to be_a(Twilio::Rails::Phone::Tree::MessageSet)
          expect(value.messages.length).to eq(1)
        end

        it "lets message: be a proc" do
          value = described_class.new(message: proc {}, hangup: true)
          expect(value.messages).to be_a(Proc)
        end
      end

      it "accepts a string" do
        expect(described_class.new(:abc).prompt).to eq(:abc)
      end

      it "accepts a symbol" do
        expect(described_class.new("abc").prompt).to eq(:abc)
      end

      it "does not accept nil" do
        expect { described_class.new(nil) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end
    end
  end

  describe Twilio::Rails::Phone::Tree::Gather, type: :model do
    describe "#initialize" do
      context "accepts a hash" do
        it "with a type as string" do
          expect(described_class.new("type" => "digits").type).to eq(:digits)
        end

        it "with a type as symbol" do
          expect(described_class.new(type: :digits).type).to eq(:digits)
        end

        it "sets digits? accessor" do
          expect(described_class.new(type: :digits).digits?).to be true
          expect(described_class.new(type: :digits).voice?).to be false
          expect(described_class.new(type: :digits).speech?).to be false
        end

        it "sets voice? accessor" do
          expect(described_class.new(type: :voice).digits?).to be false
          expect(described_class.new(type: :voice).voice?).to be true
          expect(described_class.new(type: :voice).speech?).to be false
        end

        it "sets the speech? accessor" do
          expect(described_class.new(type: :speech).digits?).to be false
          expect(described_class.new(type: :speech).voice?).to be false
          expect(described_class.new(type: :speech).speech?).to be true
        end

        it "and raises with invalid type" do
          expect { described_class.new(type: :asdf) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
        end
      end

      it "does not accept a string" do
        expect { described_class.new("whatever") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end

      it "does not accept a symbol" do
        expect { described_class.new(:asdf) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end

      it "does not accept nil" do
        expect { described_class.new(nil) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      end

      it "sets the interrupt for gather digits" do
        expect(described_class.new(type: :digits, interrupt: true).interrupt?).to be_truthy
      end

      it "defaults the interrupt for gather digits" do
        expect(described_class.new(type: :digits).interrupt?).to be_falsey
      end
    end
  end

  describe Twilio::Rails::Phone::Tree::Message, type: :model do
    it "accepts only one of say/play/pause" do
      expect { described_class.new(say: "a", play: "a") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(say: "a", pause: 1) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(pause: 1, play: "a") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(say: "a", pause: 1, play: "a") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    it "accepts a block for say and no params" do
      message = described_class.new {}
      expect(message.value).to be_nil
      expect(message.say?).to be_truthy
    end

    it "accepts a block for say and say keyword" do
      message = described_class.new(say: "hello") {}
      expect(message.value).to eq("hello")
      expect(message.say?).to be_truthy
    end

    it "does not accept a block for play" do
      expect { described_class.new(play: "a") {} }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    it "does not accept a block for pause" do
      expect { described_class.new(pause: 1) {} }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    it "accepts play as a string URL" do
      message = described_class.new(play: "http://example.com/audio.wav")
      expect(message.value).to eq("http://example.com/audio.wav")
      expect(message.play?).to be_truthy
    end

    it "doest not accept play as an invalid string URL" do
      expect {
        described_class.new(play: "not_a_url")
      }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end
  end

  describe Twilio::Rails::Phone::Tree::MessageSet, type: :model do
    it "accepts message hash as a string" do
      expect(described_class.new(message: "hello").first.value).to eq("hello")
    end

    it "accepts message as a string" do
      expect(described_class.new("hello").first.value).to eq("hello")
    end

    it "accepts message as an array of hashes" do
      value = described_class.new(message: [{say: "hello"}, {say: "there"}])
      expect(value.first.value).to eq("hello")
      expect(value.first.say?).to be_truthy
      expect(value.last.value).to eq("there")
      expect(value.last.say?).to be_truthy
    end

    it "accepts message as an array of strings" do
      value = described_class.new(message: ["hello", "there"])
      expect(value.first.value).to eq("hello")
      expect(value.first.say?).to be_truthy
      expect(value.last.value).to eq("there")
      expect(value.last.say?).to be_truthy
    end

    it "accepts message as an empty array" do
      expect(described_class.new(message: []).length).to eq(0)
    end

    it "accepts message as an array of nil" do
      expect(described_class.new(message: [nil]).length).to eq(0)
    end

    it "accepts message as an array of empty string" do
      expect(described_class.new(message: [""]).length).to eq(0)
    end

    it "accepts a message as Twilio::Rails::Phone::Tree::Message" do
      expect(
        described_class.new(message: Twilio::Rails::Phone::Tree::Message.new(say: "hello")).first.value
      ).to eq("hello")
    end

    it "does not accept message as an array of other things" do
      expect {
        described_class.new(message: [Object.new])
      }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    it "accepts message as an array of proc" do
      expect(described_class.new(message: [proc {}]).length).to eq(1)
    end

    it "does not accept message as a hash" do
      value = described_class.new(message: {say: "hello"})
      expect(value.first.value).to eq("hello")
      expect(value.first.say?).to be_truthy
    end

    it "accepts say as a string" do
      value = described_class.new(say: "hello")
      expect(value.first.value).to eq("hello")
      expect(value.first.say?).to be_truthy
    end

    it "does not accept say as an array" do
      expect {
        described_class.new(say: ["hello"])
      }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    it "accepts say as a proc" do
      expect(described_class.new(say: proc {}).length).to eq(1)
    end

    it "accepts play as a string URL" do
      value = described_class.new(play: "http://example.com/audio.wav")
      expect(value.first.value).to eq("http://example.com/audio.wav")
      expect(value.first.play?).to be_truthy
    end

    it "doest not accept play as an invalid string URL" do
      expect {
        described_class.new(play: "not_a_url")
      }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end

    it "accepts play as a proc" do
      expect(described_class.new(play: proc {}).length).to eq(1)
    end

    it "accepts pause as a hash" do
      value = described_class.new(message: {pause: 3})
      expect(value.first.value).to eq(3)
      expect(value.first.pause?).to be(true)
    end

    it "accepts pause as a hash with a string" do
      value = described_class.new(message: {pause: "3"})
      expect(value.first.value).to eq(3)
      expect(value.first.pause?).to be(true)
    end

    it "accepts pause as an array" do
      value = described_class.new(message: [{pause: "356"}])
      expect(value.first.value).to eq(356)
      expect(value.first.pause?).to be(true)
    end

    it "accepts many pauses" do
      value = described_class.new(message: [{pause: 2}, {pause: 3}])
      expect(value.first.value).to eq(2)
      expect(value.first.pause?).to be(true)
      expect(value.last.value).to eq(3)
      expect(value.last.pause?).to be(true)
    end

    it "does not accept more than one of message/say/play/pause" do
      expect { described_class.new(say: "a", play: "a") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(say: "a", message: "a") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(message: "a", play: "a") }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(message: "a", pause: 1) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(play: "a", pause: 1) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(say: "a", pause: 1) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
      expect { described_class.new(message: "a", say: "a", play: "a", pause: 1) }.to raise_error(Twilio::Rails::Phone::InvalidTreeError)
    end
  end
end
