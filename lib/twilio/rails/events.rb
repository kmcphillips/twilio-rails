# frozen_string_literal: true
module Twilio
  module Rails
    module Events
      # Base error class for errors relating to events and triggers.
      class Error < ::Twilio::Rails::Error ; end

      class Base
        # TODO

        def trigger(*args)
          # TODO
        end
      end

      class Transcription < Base
        # TODO
      end

      class PhonePromptReached < Base
        # TODO
      end

      CLASSES = {
        transcription: Twilio::Rails::Events::Transcription,
        prompt_reached: Twilio::Rails::Events::PhonePromptReached,
      }.with_indifferent_access.freeze

      class << self
        def register(event, *args) # TODO: &block
          binding.irb
          event_class = class_for!(event)

          registry[event_class.name] ||= []
          registry[event_class.name] << event_class.new(*args)

          nil
        end

        def trigger(event, *args)
          event_class = class_for!(event)

          (registry[event_class.name] || []).each do |event_instance|
            event_instance.trigger(*args)
          end

          nil
        end

        def clear!
          @registry = nil

          nil
        end

        def class_for(event)
          CLASSES[event]
        end

        def class_for!(event)
          class_for(event) || raise(Error, "Cannot find event '#{ event }'")
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
