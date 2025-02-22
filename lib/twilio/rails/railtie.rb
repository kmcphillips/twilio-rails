# frozen_string_literal: true

module Twilio
  module Rails
    class Railtie < ::Rails::Railtie
      config.before_initialize do
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym "SMS"
        end
      end

      config.after_initialize do |application|
        # TODO: This should work but it does not. I think maybe it happens too late? The same line works if you add it directly to the `application.rb` of the app. It is needed for dev mode.
        # application.config.hosts << Twilio::Rails.config.host_domain
      end

      initializer "twilio_rails.deprecator" do |app|
        app.deprecators[:twilio_rails] = Twilio::Rails.deprecator
      end
    end
  end
end
