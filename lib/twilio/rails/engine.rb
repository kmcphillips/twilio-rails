module Twilio
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Twilio::Rails

      config.to_prepare do
        Twilio::Rails.config.finalize!
      end
    end
  end
end
