# frozen_string_literal: true
module Twilio
  module Rails
    module Models
      module PhoneCaller
        extend ActiveSupport::Concern

        included do
          include Twilio::Rails::HasPhoneNumber

          has_many :phone_calls, class_name: Twilio::Rails.config.phone_call_class_name
          has_many :responses, through: :phone_calls, class_name: Twilio::Rails.config.response_class_name
        end

        class_methods do
          def for(phone_number_string)
            phone_number = Twilio::Rails::Formatter.coerce_to_valid_phone_number(phone_number_string)
            find_by(phone_number: phone_number) if phone_number.present?
          end
        end

        def location
          phone_calls.inbound.last&.location
        end

        def inbound_calls_for(tree)
          tree = tree.is_a?(Twilio::Rails::Phone::Tree) ? tree.name : tree
          phone_calls.inbound.tree(tree)
        end

        def call_count(tree)
          inbound_calls_for(tree).count
        end

        def sms_conversations
          Twilio::Rails.config.sms_conversation_class.phone_number(self.phone_number)
        end

        def response_digits(prompt:, tree:)
          response = responses.tree(tree).where(prompt_handle: prompt, timeout: false).last
          return nil unless response
          response.integer_digits
        end

        def response_reached?(prompt:, tree:)
          response_for(prompt: prompt, tree: tree).present?
        end

        def response_for(prompt:, tree:)
          responses.tree(tree).where(prompt_handle: prompt).last
        end
      end
    end
  end
end
