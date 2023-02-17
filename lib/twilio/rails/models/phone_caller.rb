# frozen_string_literal: true
module Twilio
  module Rails
    module Models
      # The core identity object, uniquely identifying an individual by their phone number. All ingoing or outgoing
      # phone calls or SMS messages are associated to a phone caller. A phone caller is automatically created when any
      # phone call or SMS message is sent or received.
      module PhoneCaller
        extend ActiveSupport::Concern

        included do
          include Twilio::Rails::HasPhoneNumber

          has_many :phone_calls, class_name: Twilio::Rails.config.phone_call_class_name
          has_many :responses, through: :phone_calls, class_name: Twilio::Rails.config.response_class_name
        end

        class_methods do
          # Finds a phone caller by phone number string or object, regardless of formatting. Returns `nil` if not found.
          #
          # @param phone_number_string [String, Twilio::Rails::PhoneNumber] The phone number to find the record.
          # @return [Twilio::Rails::Models::PhoneCaller, nil] The phone caller record or `nil` if not found.
          def for(phone_number_string)
            phone_number = Twilio::Rails::Formatter.coerce_to_valid_phone_number(phone_number_string)
            find_by(phone_number: phone_number) if phone_number.present?
          end
        end

        # @return [String] A well formatted string with the city/state/country of the phone caller, if available.
        def location
          phone_calls.inbound.last&.location
        end

        # @return [Array<Twilio::Rails::Models::PhoneCall>] All inbound phone calls for the given phone tree or tree name.
        def inbound_calls_for(tree)
          tree = tree.is_a?(Twilio::Rails::Phone::Tree) ? tree.name : tree
          phone_calls.inbound.tree(tree)
        end

        # @return [Array<Twilio::Rails::Models::PhoneCall>] All outbound phone calls for the given phone tree or tree name.
        def outbound_calls_for(tree)
          tree = tree.is_a?(Twilio::Rails::Phone::Tree) ? tree.name : tree
          phone_calls.outbound.tree(tree)
        end

        # @return [Integer] The number of inbound phone calls for the given phone tree or tree name.
        def call_count(tree)
          inbound_calls_for(tree).count
        end

        # @return [Array<Twilio::Rails::Models::SmsConversation>] All SMS conversations for the phone caller.
        def sms_conversations
          Twilio::Rails.config.sms_conversation_class.phone_number(self.phone_number)
        end

        # Returns the digits as entered through the keypad during a phone call as `gather:`. Returns `nil` if the
        # response is not found, if the response has no digits, or if the response was a timeout. Useful for doing
        # branching logic within a phone tree, such as "Press 2 for sales..." etc..
        #
        # @param prompt [String, Symbol] The prompt handle to query.
        # @param tree [String, Symbol, Twilio::Rails::Phone::Tree] The tree or name of the tree to query.
        # @return [Integer, nil] The digits as entered by the caller or `nil` if not found or not present.
        def response_digits(prompt:, tree:)
          response = responses.tree(tree).where(prompt_handle: prompt, timeout: false).last
          return nil unless response
          response.integer_digits
        end

        # Checks if this phone caller has ever reached a response in a given phone tree. This is useful for building
        # phone trees and determining if a phone caller has reached a certain point in the tree before or not.
        #
        # @param prompt [String, Symbol] The prompt handle to query.
        # @param tree [String, Symbol, Twilio::Rails::Phone::Tree] The tree or name of the tree to query.
        # @return [true, false] If the response has been reached or not.
        def response_reached?(prompt:, tree:)
          response_for(prompt: prompt, tree: tree).present?
        end

        # Finds the most recent {Twilio::Rails::Models::Response} for the given prompt and tree. This is useful for
        # building phone trees and finding previous responses to prompts. Returns `nil` if no response is found.
        #
        # @param prompt [String, Symbol] The prompt handle to find the response for.
        # @param tree [String, Symbol, Twilio::Rails::Phone::Tree] The tree or name of the tree in which to find the response.
        # @return [Twilio::Rails::Models::Response, nil] The response or `nil` if not found.
        def response_for(prompt:, tree:)
          responses.tree(tree).where(prompt_handle: prompt).last
        end
      end
    end
  end
end
