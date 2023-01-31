# frozen_string_literal: true
module Twilio
  module Rails
    module Models
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

        def is?(tree:, prompt:)
          trees = Array(tree).map { |t| t.is_a?(Twilio::Rails::Phone::Tree) ? t.name : t.to_s }

          from?(tree: tree) && Array(prompt).map(&:to_s).reject(&:blank?).include?(self.prompt_handle)
        end

        def from?(tree:)
          trees = Array(tree).map { |t| t.is_a?(Twilio::Rails::Phone::Tree) ? t.name : t.to_s }

          trees.include?(self.phone_call.tree_name)
        end

        def integer_digits
          return nil unless digits.present?
          return nil unless digits =~ /\A[0-9]+\Z/
          digits.to_i
        end

        def pound_star?
          !!(digits =~ /\A[#*]+\Z/)
        end
        alias_method :star_pound?, :pound_star?

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

        def answer_yes?
          transcription_matches?(Twilio::Rails.config.yes_responses)
        end

        def answer_no?
          transcription_matches?(Twilio::Rails.config.no_responses)
        end

        def first_for_phone_call?(include_timeouts: true)
          return false unless id
          finder = phone_call.responses.prompt(prompt_handle).order(id: :asc)
          finder = finder.where(timeout: false) if !include_timeouts
          finder.first&.id == id
        end

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
