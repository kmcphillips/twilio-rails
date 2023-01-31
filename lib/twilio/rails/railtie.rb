# frozen_string_literal: true
module Twilio
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_initialize do
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'SMS'
        end
      end

      config.after_initialize do
        Twilio::Rails.config.finalize!
      end
    end
  end
end
