# frozen_string_literal: true
module Twilio
  module Rails
    module Models
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

        class_methods do
          def caller_count_for_tree(tree)
            tree = tree.is_a?(Twilio::Rails::Phone::Tree) ? tree.name : tree
            tree(tree).pluck(:phone_caller_id).uniq.count
          end
        end

        def answering_machine?
          outbound? && answered_by == "machine_start"
        end

        # possible call statuses: "queued", "ringing", "in-progress", "canceled", "completed", "busy", "no-answer", "failed"
        def no_answer?
          outbound? && call_status.in?(["busy", "failed", "no-answer"])
        end

        def completed?
          call_status.in?(["completed"])
        end

        def in_progress?
          call_status.blank? || call_status.in?(["queued", "ringing", "in-progress"])
        end

        def location
          Twilio::Rails::Formatter.location(city: from_city, country: from_country, province: from_province)
        end

        def tree
          @tree ||= Twilio::Rails.config.phone_trees.for(tree_name)
        end

        def for?(tree:)
          trees = Array(tree).map { |t| t.is_a?(Twilio::Rails::Phone::Tree) ? t.name : t.to_s }

          trees.include?(tree_name)
        end

        def metadata
          result = []

          result << "#{responses.count} response".pluralize(responses.count) if responses.count > 0
          result << "#{recordings.count} recording".pluralize(recordings.count) if recordings.count > 0
          result << "#{artifacts.count} artifact".pluralize(artifacts.count) if artifacts.count > 0

          result.reject(&:blank?).join(", ")
        end

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
