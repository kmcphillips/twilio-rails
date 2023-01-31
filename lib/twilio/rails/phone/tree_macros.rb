# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      # This module is available as `macros` in context of generating phone trees. It provides a set of shortcuts for
      # common or verboase actions. It can be extended with custom macros using the config option {Twilio::Rails::Configuration#include_phone_macros}
      module TreeMacros
        extend self

        # Gather one digit, allowing the current speech to be interrupted and stopped when a digit is pressed, with a
        # configurable timeout that defaults to 6 seconds.
        #
        # @param timeout [Integer] the number of seconds to wait for a digit before timing out, defaults to 6 seconds.
        # @return [Hash] formatted to pass to `gather:`.
        def digit_gather_interruptable(timeout: 6)
          timeout = timeout.to_i.presence || 6
          timeout = 6 if timeout < 1

          {
            type: :digits,
            timeout: timeout.to_i.presence || 6,
            number: 1,
            interrupt: true,
            finish_on_key: "",
          }
        end

        # Split a number into its digits and join them with commas, in order for it to be read out as a list of digits.
        # @example
        #   digits(123)
        #   "1, 2, 3"
        #
        # @param num [Integer, String] the integer number to split into digits.
        # @return [String] the digits joined with commas.
        def digits(num)
          return "" if num.blank?
          num.to_s.split("").join(", ")
        end

        # Pause for a number of seconds, defaults to 1 second. Useful when putting space between segments of speech.
        #
        # @param seconds [Integer] the number of seconds to pause for, defaults to 1 second.
        # @return [Hash] formatted to pass to `message:`.
        def pause(seconds=nil)
          {
            pause: (seconds.presence || 1),
          }
        end

        # Format a list of choices such that they are a numbered list for a phone tree menu, and can be passed directly
        # into a `say:`. This pairs perfectly with {#numbered_choice_response_includes?} for creating menus. The array
        # of choices must be larger than 1 and less than 10, otherwise a {Twilio::Rails::Phone::Error} will be raised.
        #
        # @example
        #   numbered_choices(["store hours", "accounting", "warehouse"])
        #   [
        #      "For store hours, press 1.",
        #      "For accounting, press 2.",
        #      "For store warehouse, press 3.",
        #   ]
        #
        # @param choices [Array<String>] the list of choices in numbered order.
        # @param prefix [String] the prefix to use before each choice, defaults to "For".
        # @return [Array<String>] the list of choices with numbers and prefixes formatted for `say:`.
        def numbered_choices(choices, prefix: nil)
          raise Twilio::Rails::Phone::Error, "`numbered_choices` macro got an empty array" if choices.empty?
          raise Twilio::Rails::Phone::Error, "`numbered_choices` macro cannot be more than 9" if choices.length > 9
          prefix ||= "For"
          choices.each_with_index.map { |choice, index| "#{ prefix } #{ choice }, press #{ index + 1 }." }.join(" ")
        end

        # Validates if the response object includes a digit that is within the range of the choices array. This pairs
        # directly with {#numbered_choices} for creating menus and validating the input. The array of choices must be
        # larger than 1 and less than 10, otherwise a {Twilio::Rails::Phone::Error} will be raised.
        #
        # @param choices [Array<String>] the list of choices in numbered order.
        # @param response [Twilio::Rails::Phone::Models::Response] the response object to validate.
        # @return [true, false] whether the response includes a digit that is within the range of the choices. Returns
        # false also if there are no digits or the digit is out of range.
        def numbered_choice_response_includes?(choices, response:)
          raise Twilio::Rails::Phone::Error, "`numbered_choice_response_includes?` macro got an empty array" if choices.empty?
          raise Twilio::Rails::Phone::Error, "`numbered_choice_response_includes?` macro cannot be more than 9" if choices.length > 9
          !!(response.integer_digits && response.integer_digits > 0 && response.integer_digits <= choices.length)
        end

        # The list of configured answers that are considered "yes" from {Twilio::Rails::Configuration#yes_responses}.
        #
        # @return [Array<String>] the list of configured answers that are considered "yes".
        def answers_yes
          Twilio::Rails.config.yes_responses
        end

        # The list of configured answers that are considered "no" from {Twilio::Rails::Configuration#no_responses}.
        #
        # @return [Array<String>] the list of configured answers that are considered "no".
        def answers_no
          Twilio::Rails.config.no_responses
        end

        # Finds and validates the existence of a file in the `public` folder. Formats that link to include the
        # configured hose from {Twilio::Rails::Configuration#host}, and returns a fully qualified URL to the file. This
        # is useful for playing audio files in a `message:` block. If the file is not found
        # {Twilio::Rails::Phone::Error} is raised.
        #
        # @param filename [String] the filename of the file to play located in the `public` folder.
        # @return [String] the fully qualified URL to the file.
        def public_file(filename)
          filename = filename.gsub(/^\//, "")
          local_path = ::Rails.public_path.join(filename)

          if File.exist?(local_path)
            "#{ ::Twilio::Rails.config.host }/#{ filename }"
          else
            raise Twilio::Rails::Phone::Error, "Cannot find public file '#{ filename }' at #{ local_path }"
          end
        end

        # Wraps the result of {#public_file} in a hash that can be used directly as a `message:`.
        #
        # @param filename [String] the filename of the file to play located in the `public` folder.
        # @return [Hash] formatted to pass to `message:`.
        def play_public_file(filename)
          { play: public_file(filename) }
        end
      end
    end
  end
end
