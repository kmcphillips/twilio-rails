module Twilio
  module Rails
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
