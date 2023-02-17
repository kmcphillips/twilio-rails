# frozen_string_literal: true
module Twilio
  module Rails
    module Models
      # A response object is created for every prompt in a phone call. It is associated to a
      # {Twilio::Rails::Models::PhoneCall} in order, and contains transcriptions, digits, recordings, timestamps, and
      # all other metadata.
      module Response
        extend ActiveSupport::Concern

        included do
          include Twilio::Rails::HasTimeScopes

          validates :prompt_handle, presence: true

          belongs_to :phone_call, class_name: Twilio::Rails.config.phone_call_class_name
          belongs_to :recording, required: false, class_name: Twilio::Rails.config.recording_class_name

          delegate :phone_caller, to: :phone_call

          scope :completed, -> { where(timeout: false) }
          scope :recent_transcriptions, ->(number=5) { completed.order(created_at: :desc).where.not(transcription: nil).limit(number) }
          scope :final_timeout_check, ->(count:, prompt_handle:) {
            prompt(prompt_handle).order(created_at: :desc).limit(count)
          }
          scope :tree, ->(name) { joins(:phone_call).where(phone_calls: { tree_name: name }) }
          scope :prompt, ->(prompt_handle) { where(prompt_handle: prompt_handle) }
          scope :in_order, -> { order(created_at: :asc) }
          scope :transcribed, -> { where(transcribed: true) }

          after_commit :recalculate_phone_call_length, on: :create
        end

        # Checks if the response is for a given prompt or promts, and given tree or trees or tree names.
        #
        # @param tree [Twilio::Rails::Phone::Tree, String, Symbol, Array] The tree or tree name or an array of them.
        # @param prompt [String, Symbol, Array] The prompt handle or an array of them.
        # @return [true, false] true if the response is for the given prompt and tree.
        def is?(tree:, prompt:)
          trees = Array(tree).map { |t| t.is_a?(Twilio::Rails::Phone::Tree) ? t.name : t.to_s }

          from?(tree: tree) && Array(prompt).map(&:to_s).reject(&:blank?).include?(self.prompt_handle)
        end

        # Checks if the response is for a given tree or trees or tree names.
        #
        # @param tree [Twilio::Rails::Phone::Tree, String, Symbol, Array] The tree or tree name or an array of them.
        # @return [true, false] true if the response is for the given tree.
        def from?(tree:)
          trees = Array(tree).map { |t| t.is_a?(Twilio::Rails::Phone::Tree) ? t.name : t.to_s }

          trees.include?(self.phone_call.tree_name)
        end

        # Returns the digits as an `Integer` entered through the keypad during a phone call as `gather:`. Returns `nil`
        # if the response has no digits, or if the response contains `*` or `#` characters. Useful for doing branching
        # logic within a phone tree, such as "Press 2 for sales..." etc..
        #
        # @return [Integer, nil] The digits as entered by the caller or `nil` if not found or not present.
        def integer_digits
          return nil unless digits.present?
          return nil unless digits =~ /\A[0-9]+\Z/
          digits.to_i
        end

        # Returns true if the digits entered through the keypad during a phone call as `gather:` contain only `*` or `#`
        #
        # @return [true, false] true if the digits are only `*` or `#`.
        def pound_star?
          !!(digits =~ /\A[#*]+\Z/)
        end
        alias_method :star_pound?, :pound_star?

        # Checks if any of the passed in patterns match the transcription. Will always return false if the
        # transcription is blank. Patterns can be a `String`, `Symbol`, `Regexp`, or an `Array` of any of those. Will
        # raise `ArgumentError` if no transcriptions are passed in.
        #
        # @param patterns [String, Symbol, Regexp, Array] The patterns to match against.
        # @return [true, false] true if any of the patterns match the transcription.
        def transcription_matches?(*patterns)
          patterns = Array(patterns).flatten
          raise ArgumentError, "transcription must match against at least one pattern" if patterns.blank?

          return false if transcription.blank?

          patterns.each do |pattern|
            case pattern
            when Regexp
              return true if pattern.match?(transcription)
            when String, Symbol
              return true if transcription.downcase.include?(pattern.to_s.downcase)
            else
              raise ArgumentError, "can only match a String or Regexp"
            end
          end

          false
        end

        # Returns true if the transcription matches any of the configured "yes". Will return false if the transcription
        # is blank. See {Twilio::Rails::Configuration#yes_responses} for the default values. It is possible for
        # {#answer_yes?} and {#answer_no?} to both be false.
        #
        # @return [true, false] true if the transcription matches any of the configured "yes" responses.
        def answer_yes?
          transcription_matches?(Twilio::Rails.config.yes_responses)
        end

        # Returns true if the transcription matches any of the configured "no". Will return false if the transcription
        # is blank. See {Twilio::Rails::Configuration#yes_responses} for the default values. It is possible for
        # {#answer_yes?} and {#answer_no?} to both be false.
        #
        # @return [true, false] true if the transcription matches any of the configured "no" responses.
        def answer_no?
          transcription_matches?(Twilio::Rails.config.no_responses)
        end

        # Returns true if this response is the first time the caller has encountered the given prompt for this phone
        # call. The parameter `include_timeouts` defaults to true and flags whether or not to include responses that
        # are timeouts. If the response is unsaved it will always return false.
        #
        # @param include_timeouts [true, false] Whether or not to include timeouts responses.
        # @return [true, false] if this is the first time the caller has encountered this prompt in this phone call.
        def first_for_phone_call?(include_timeouts: true)
          return false unless id
          finder = phone_call.responses.prompt(prompt_handle).order(id: :asc)
          finder = finder.where(timeout: false) if !include_timeouts
          finder.first&.id == id
        end

        # Returns true if this response is the first time the caller has encountered the given prompt across *any* phone
        # call. The parameter `include_timeouts` defaults to true and flags whether or not to include responses that
        # are timeouts. If the response is unsaved it will always return false.
        #
        # @param include_timeouts [true, false] Whether or not to include timeouts responses.
        # @return [true, false] if this is the first time the caller has encountered this prompt in any phone call.
        def first_for_phone_caller?(include_timeouts: true)
          return false unless id
          finder = phone_caller.responses.prompt(prompt_handle).tree(phone_call.tree_name).order(id: :asc)
          finder = finder.where(timeout: false) if !include_timeouts
          finder.first&.id == id
        end

        private

        def recalculate_phone_call_length
          phone_call.recalculate_length
          true
        end
      end
    end
  end
end
