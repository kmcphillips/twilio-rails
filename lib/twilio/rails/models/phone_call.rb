# frozen_string_literal: true
module Twilio
  module Rails
    module Models
      # The record of a phone call. Can be inbound or outbound. The associated {Twilio::Rails::Models::Response} objects
      # in order track the progress of the call.
      module PhoneCall
        extend ActiveSupport::Concern

        included do
          include Twilio::Rails::HasDirection
          include Twilio::Rails::HasTimeScopes

          validates :sid, presence: true
          validates_associated :phone_caller

          belongs_to :phone_caller, class_name: Twilio::Rails.config.phone_caller_class_name

          has_many :responses, dependent: :destroy, class_name: Twilio::Rails.config.response_class_name
          has_many :recordings, dependent: :destroy, class_name: Twilio::Rails.config.recording_class_name

          scope :recent, -> { order(created_at: :desc).limit(10) }
          scope :tree, ->(name) { where(tree_name: name) }
          scope :called_today, -> { where("created_at > ?", Time.now - 1.day).includes(:phone_caller).order(created_at: :asc) }
          scope :in_progress, -> { where(call_status: "in-progress") }

          after_save :unanswered_callback
        end

        # All possible call statuses:
        # "queued", "initiated", "ringing", "in-progress", "completed", "canceled", "busy", "no-answer", "failed"

        class_methods do
          # Returns the number of unique callers for a given tree.
          #
          # @param tree [String, Twilio::Rails::Phone::Tree, String, Symbol] The tree or name of the tree.
          # @return [Integer] The number of unique callers for the tree.
          def caller_count_for_tree(tree)
            tree = tree.is_a?(Twilio::Rails::Phone::Tree) ? tree.name : tree
            tree(tree).pluck(:phone_caller_id).uniq.count
          end
        end

        # Indicates if the call was answered by an answering machine. Only will return true if answering machine
        # detection is enabled. Is always false for inbound calls.
        #
        # @return [true, false] true if the call was answered by an answering machine.
        def answering_machine?
          outbound? && answered_by == "machine_start"
        end

        # Indicates if the call was not answered, busy, or failed. Is always false for inbound calls.
        #
        # @return [true, false] true if the call was not answered by a person.
        def no_answer?
          outbound? && call_status.in?(["busy", "failed", "no-answer"])
        end

        # Checks if the call is in the completed state. This does not cover all possible states for a call that is not
        # in progress. See {#in_progress?} to check if a call is finished or not.
        #
        # @return [true, false] true if the call is in the completed state.
        def completed?
          call_status.in?(["completed"])
        end

        # Checks if that call is in a state where it is currently in progress with the caller. This includes ringing,
        # queued, initiated, or in progress. Use this method to check if the call has finished or not.
        #
        # @return [true, false] true if the call is currently ringing, queued, or in progress.
        def in_progress?
          call_status.blank? || call_status.in?(["queued", "initiated", "ringing", "in-progress"])
        end

        # A formatted string for the location data of the caller provided by Twilio, if any is available.
        #
        # @return [String] The location of the caller.
        def location
          Twilio::Rails::Formatter.location(city: from_city, country: from_country, province: from_province)
        end

        # @return [String] The {Twilio::Rails::Phone::Tree} for the call.
        def tree
          @tree ||= Twilio::Rails.config.phone_trees.for(tree_name)
        end

        # Checks if the call is for a given tree or trees, by class or by name.
        #
        # @param tree [Twilio::Rails::Phone::Tree, String, Symbol, Array] The tree or name of the tree, or an array of either.
        # @return [true, false] true if the call is for the given tree or trees.
        def for?(tree:)
          trees = Array(tree).map { |t| t.is_a?(Twilio::Rails::Phone::Tree) ? t.name : t.to_s }

          trees.include?(tree_name)
        end

        # Updates the `length_seconds` attribute based on the time difference between the first and most recent
        # responses in the phone call. Called by {Twilio::Rails::Phone::Response} when it is updated.
        #
        # @return [Integer] The length of the call in seconds.
        def recalculate_length
          first_response = responses.in_order.first
          last_response = responses.in_order.last
          result = 0
          estimated_length_seconds = 5 # scientifically determined to be extremely accurate

          result = last_response.created_at.to_i - first_response.created_at.to_i + estimated_length_seconds if first_response
          update!(length_seconds: result)
          result
        end

        private

        def unanswered_callback
          if saved_changes.key?("call_status") && no_answer?
            Twilio::Rails::Phone::UnansweredJob.set(wait: 10.seconds).perform_later(phone_call_id: id)
          end

          if saved_changes.key?("answered_by") && answering_machine?
            Twilio::Rails::Phone::UnansweredJob.set(wait: 10.seconds).perform_later(phone_call_id: id)
          end
        end
      end
    end
  end
end
