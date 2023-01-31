# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      # Base class for all phone trees which provides the DSL to define a tree. To define a phone tree start by
      # generating a sublcass.
      #
      #     rails generate twilio:rails:phone_tree LeaveFeedback
      #
      # This will create a new class in `app/phone_trees/leave_feedback_tree.rb` which will subclass this class. It must be
      # registered with the framework in the initializer for it to be available. The generator does this.
      #
      #     # config/initializers/twilio_rails.rb
      #     config.phone_trees.register { LeaveFeedbackTree }
      #
      # Then define the tree using the DSL methods provided by this class. For example:
      #
      #     class LeaveFeedbackTree < Twilio::Rails::Phone::BaseTree
      #       voice "Polly.Matthew-Neural"
      #       final_timeout_message "Sorry, you don't appear to be there. Goodbye."
      #       unanswered_call ->(phone_call) { MyMailer.send_followup(phone_call).deliver_later }
      #       invalid_phone_number "Sorry, we can only accept calls from North America. Goodbye."
      #
      #       greeting message: "Hello, and thank you for calling.",
      #         prompt: :leave_feedback
      #
      #       prompt :leave_feedback,
      #         message: "Please leave your feedback after the tone, and press pound when you are finished.",
      #         gather: {
      #           type: :voice,
      #           timeout: 30,
      #           transcribe: true,
      #         },
      #         after: ->(response) {
      #           if MyServiceObject.new(response.phone_caller).has_followup_message?
      #             { prompt: :followup_message }
      #           else
      #             {
      #               message: "Thank you for your feedback. Have a nice day.",
      #               hangup: true,
      #             }
      #           end
      #         }
      #
      #       prompt :followup_message,
      #         message: ->(response) {
      #           [
      #             { play: "http://example.com/followup_message_sound.mp3" },
      #             { say: MyServiceObject.new(response.phone_caller).followup_message_text },
      #           ]
      #         },
      #         after: {
      #           message: "Thank you. Have a nice day.",
      #           hangup: true,
      #         }
      #     end
      class BaseTree
        class << self
          # Accepts a string with the voice parameter to be used throughout the phone tree, unless overridden for a
          # given message. See the Twilio documentation for a list of available voices. The voices are dependent on
          # locale, and can also accept Amazon Polly voices. The default is "male".
          # https://www.twilio.com/docs/voice/twiml/say/text-speech
          #
          # @param voice_name [String] the name of the voice to use.
          # @return [nil]
          def voice(voice_name)
            tree.config[:voice] = voice_name
            nil
          end

          # The `message:` object that is played to the caller if the phone tree is expecting input but none is
          # received. The default number of attempts before this is called is 3, configured in `final_timeout_attempts`.
          # The default value is a simple "Goodbye."
          def final_timeout_message(message)
            tree.config[:final_timeout_message] = message
            nil
          end

          # The entrypoint and first call for any incoming or outgoing phone call. It should only be called once as
          # there is only one greeting. Subsequent calls will overwrite the earlier ones. It accepts an optional
          # `message:` object which will be played to the caller. See the documentation for {.prompt} for what a message
          # can contain. It then accepts a required `prompt:` which is the next prompt in the flow of the call.
          #
          # @param message [String, Hash, Array, Proc] The message to play to the caller.
          # @param prompt [Symbol, Hash, Proc] The name of the next prompt.
          # @return [nil]
          def greeting(message: nil, prompt:)
            tree.greeting = Twilio::Rails::Phone::Tree::After.new(message: message, prompt: prompt)
            nil
          end

          # Defines a prompt in the phone tree. It accepts a required `name:` which must be unique within the tree.
          #
          # It accepts an optional `message:` object which will be played to the caller. A message must be one of:
          # * `nil`: No message will be played.
          # * `String`: A string that will be read to the caller using text-to-speech. This is the equivalent of
          #   `{ say: "a string" }`.
          # * `Hash`: A hash that contain only the following keys:
          #   * `{ say: "hello" }`: A string that will be read to the caller using text-to-speech. Optionally also
          #     accepts a `voice:` key which will override the default voice for this message.
          #   * `{ play: "https://example.com/sound.mp3" }`: A URL to a "wav" or "mp3" file that will be played to the
          #     caller via Twilio.
          #   * `{ pause: 1 }`: Pause in silence for the given number of seconds.
          # * `Array`: An array that contains any number of the above.
          # * `Proc`: A proc that will be called when the prompt is reached. The prompt will receive the previous
          #   {Twilio::Rails::Models::Response} instance as an argument. The proc must return one of the above.
          #
          # It accepts an optional `gather:` object which, if present, will be used to gather input from the caller.
          # After the optional message completes, the gather will collect the input. The gather object must be a hash
          # with one of the following types:
          # * `{ type: :digits }`: Collects one or more integer digits from the caller's keypad. Those digits will be
          #   stored in the `digits` field of the {Twilio::Rails::Models::Response} instance. Digits accepts the
          #   following configuration keys:
          #   * `:timeout`: The number of seconds to wait for input before timing out and falling through to the
          #     `after:`. The default is 5.
          #   * `:number`: The number of digits to collect. The default is 1.
          #   * `:interrupt`: Weather pressing a key will interrupt the message, or if the gather will not start
          #     until the message is complete. The default is `false`.
          # * `{ type: :voice }`: Records and collects the phone caller's voice as audio. The framework handles
          #   updating the `url` and fetching the audio file as a {Twilio::Rails::Models::Recording} attached to the
          #   response instance. However, this all happens asynchronously with no guarantee of time or success. Voice
          #   accepts the following configuration keys:
          #   * `:length`: The number of seconds to record. The default is 10.
          #   * `:beep`: A boolean if the gather is preceeded by a beep. The default is `true`.
          #   * `:transcribe`: A boolean if Twilio should attempt to transcribe the audio and send it back as text. The
          #     framework handles this all asynchronously and will update the `transcription` field. Default is `false`.
          #   * `:profanity_filter`: Replaces any profanity in the transcription with ***. Default is `false`.
          # * `{ type: :speech }`: Collects speech from the caller using a specialzed model designed to better identify
          #   utterances of digits, commands, conversations, etc.. This feature is not not fully tested or implemented
          #   yet in the framework.
          #
          # It accepts an required `after:` object which, will be used to determine the next prompt in the call flow.
          # The after object must be one of:
          # * `Symbol`: The name of the next prompt in the flow.
          # * `Hash`: A hash that contains:
          #   * `:message`: An optional message to play before the next prompt. See the above documentation for what
          #     a message can contain.
          #   * `:prompt`: The name of the next prompt in the flow.
          #   * `:hangup`: A boolean if the call should be hung up after the message. Only one of prompt and hangup can
          #     be present.
          # * `Proc`: A proc that will be called after the message and gather have been called. The proc will receive
          #   the current {Twilio::Rails::Models::Response} instance as an argument. The proc must return one of the
          #   above.
          def prompt(prompt_name, message: nil, gather: nil, after:)
            tree.prompts[prompt_name] = Twilio::Rails::Phone::Tree::Prompt.new(name: prompt_name, message: message, gather: gather, after: after)
            nil
          end

          # Accepts a proc which will be called when a call goes unanswered, or is answered by an answering machine.
          # The proc will be called asynchronously in a job. The proc will be passed the
          # {Twilio::Rails::Models::PhoneCall} instance for the call. It is called after the call has been completed
          # so cannot control the flow of the call. It is intended to be used as a hook to handle application logic for
          # unanswered calls. The default is `nil` and no action is taken.
          #
          # @param proc [Proc] the proc to call when a call goes unanswered, must accept a phone call instance.
          # @return [nil]
          def unanswered_call(proc)
            tree.unanswered_call = proc
            nil
          end

          # The `message:` object that played to the caller if a call from an invalid phone number is received. The
          # important case here is a number from outside of North America. This is currently a limitation of the
          # framework. The default is `nil` and no action is taken. See the documentation for {.prompt} for what a
          # message object can contain.
          #
          # @param message [String, Hash, Array, Proc] The message to play to the caller.
          def invalid_phone_number(message)
            tree.config[:invalid_phone_number] = message
            nil
          end

          # The string name of the tree used to look it up and identify it in the registry and used in the routes. It
          # must be unique and use URL safe characters. It defaults to the class name but can be overridden here.
          #
          # @return [String] the name of the tree.
          def tree_name
            self.name.demodulize.underscore.sub(/_tree\z/, "")
          end

          # The instance of {Twilio::Rails::Phone::Tree} built from the DSL. Should be treated as read-only. Used
          # mostly internally by the framework. It is named according to {.tree_name}.
          #
          # @return [Twilio::Rails::Phone::Tree] the tree instance.
          def tree
            @tree ||= Twilio::Rails::Phone::Tree.new(tree_name)
          end

          # A module of convenience macros used in prompts to prevent repetition or wordy tasks. See
          # {Twilio::Rails::Phone::TreeMacros} for the available methods. The macros do not have access to any instance
          # information and must be passed any context they require.
          #
          # Additional macros can be added through the application config. See {Twilio::Rails::Configuration#include_phone_macros}.
          #
          # @return [Twilio::Rails::Phone::TreeMacros] the module of macros.
          def macros
            Twilio::Rails::Phone::TreeMacros
          end
        end
      end
    end
  end
end
