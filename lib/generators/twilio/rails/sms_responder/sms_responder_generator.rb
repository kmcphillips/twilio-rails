# frozen_string_literal: true
class Twilio::Rails::SmsResponderGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def copy_template_responder
    template "responder.rb.erb", "app/sms_responders/#{file_name}_responder.rb"
  end

  def register_responder
    insert_into_file "config/initializers/twilio_rails.rb", "\n  config.sms_responders.register { #{class_name}Responder }", before: "\nend\n"
  end
end
