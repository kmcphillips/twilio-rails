# frozen_string_literal: true

class Recording < ApplicationRecord
  include Twilio::Rails::Models::Recording
end
