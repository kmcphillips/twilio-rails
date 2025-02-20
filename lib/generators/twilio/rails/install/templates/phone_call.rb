# frozen_string_literal: true

class PhoneCall < ApplicationRecord
  include Twilio::Rails::Models::PhoneCall
end
