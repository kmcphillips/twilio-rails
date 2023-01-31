module Twilio
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Twilio::Rails
    end
  end
end
