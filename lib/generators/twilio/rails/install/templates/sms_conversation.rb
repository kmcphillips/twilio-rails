# frozen_string_literal: true

class SMSConversation < ApplicationRecord
  include Twilio::Rails::Models::SMSConversation
end
