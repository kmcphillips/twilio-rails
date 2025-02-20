# frozen_string_literal: true

class Message < ApplicationRecord
  include Twilio::Rails::Models::Message
end
