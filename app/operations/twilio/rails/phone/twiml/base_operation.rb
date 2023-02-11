# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class BaseOperation < Twilio::Rails::Phone::BaseOperation
          protected

          # Adds messages to the TwiML response from the passed in message set. This mutates the passed in TwiML object,
          # which isn't ideal.
          #
          # @param twiml [Twilio::TwiML::VoiceResponse] the TwiML response object to add messages to.
          # @param message_set [Twilio::Rails::Phone::Tree::MessageSet, Hash, Proc, Array, String] the message or messages to add to the TwiML response.
          # @param response [Twilio::Rails::Phone::Response] the response passed to the proc when they are called.
          def add_messages(twiml, message_set:, response:)
            message_set = message_set.call(response) if message_set.is_a?(Proc)
            message_set = Twilio::Rails::Phone::Tree::MessageSet.new(message: message_set) unless message_set.is_a?(Twilio::Rails::Phone::Tree::MessageSet)

            message_set.each do |message|
              message = message.call(response) if message.is_a?(Proc)
              message = Twilio::Rails::Phone::Tree::Message.new(**message) if message.is_a?(Hash)
              next if message.blank?
              message = Twilio::Rails::Phone::Tree::Message.new(say: message, voice: tree.config[:voice]) if message.is_a?(String)

              raise Twilio::Rails::Phone::InvalidTreeError "unknown message #{ message } is a #{ message.class }" unless message.is_a?(Twilio::Rails::Phone::Tree::Message)

              # TODO: if we want to make a transcript of sent messages this is where we would record outgoing messages

              if message.say?
                value = message.value
                value = message.value.call(response) if message.value.is_a?(Proc)
                twiml.say(voice: message.voice || tree.config[:voice], message: value)
              elsif message.play?
                value = message.value
                value = message.value.call(response) if message.value.is_a?(Proc)
                twiml.play(url: value)
              elsif message.pause?
                twiml.pause(length: message.value)
              else
                raise Twilio::Rails::Phone::InvalidTreeError "unknown message #{ message }"
              end
            end
          end
        end
      end
    end
  end
end
