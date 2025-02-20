# frozen_string_literal: true

class PhoneCaller < ApplicationRecord
  include Twilio::Rails::Models::PhoneCaller
end
