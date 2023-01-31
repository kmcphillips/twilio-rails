# frozen_string_literal: true
module Twilio
  module Rails
    module Models
      # A message sent or received via SMS. Belongs to a {Twilio::Rails::Models::SmsConversation}. Has a direction to
      # indicate whether it was sent or received.
      module Message
        extend ActiveSupport::Concern

        included do
          include Twilio::Rails::HasDirection
          include Twilio::Rails::HasTimeScopes

          belongs_to :sms_conversation, class_name: Twilio::Rails.config.sms_conversation_class_name

          scope :in_order, -> { order(created_at: :asc) }
        end
      end
    end
  end
end
