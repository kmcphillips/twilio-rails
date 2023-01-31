# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      module Twiml
        class BaseOperation < Twilio::Rails::Phone::BaseOperation
          protected

          def add_messages(twiml, message_set:, response:)
            message_set = message_set.call(response) if message_set.is_a?(Proc)
            message_set = Twilio::Rails::Phone::Tree::MessageSet.new(message: message_set) unless message_set.is_a?(Twilio::Rails::Phone::Tree::MessageSet)

            message_set.each do |message|
              message = message.call(response) if message.is_a?(Proc)
              message = Twilio::Rails::Phone::Tree::Message.new(**message) if message.is_a?(Hash)
              next if message.blank?

              if message.is_a?(String)
                twiml.say(voice: tree.config[:voice], message: message)
              elsif message.say?
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
