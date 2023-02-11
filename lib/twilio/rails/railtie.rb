# frozen_string_literal: true
module Twilio
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_initialize do
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'SMS'
        end
      end

      config.after_initialize do |application|
        Twilio::Rails.config.finalize!

        # TODO: This should work but it does not. I think maybe it happens too late? The same line works if you add it directly to the application config.
        application.config.hosts << Twilio::Rails.config.host_domain
      end
    end
  end
end
