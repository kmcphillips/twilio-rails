# frozen_string_literal: true
namespace :twilio do
  namespace :rails do
    desc "Show the available values to config in Twilio"
    task config: :environment do
      if Twilio::Rails.config.host.blank?
        puts "Twilio::Rails.config.host is not set. Set it in the `config/initializers/twilio_rails.rb` file."
      elsif Twilio::Rails.config.host == "https://example.com"
        puts "Twilio::Rails.config.host is set to a test value. Set it in the `config/initializers/twilio_rails.rb` file."
      else
        http_methods = if Twilio::Rails.config.controller_http_methods.length == 1
          "HTTP #{ Twilio::Rails.config.controller_http_methods.first.to_s.upcase }"
        else
          "HTTP POST or HTTP GET"
        end

        puts "Log into the Twilio web console: https://console.twilio.com"
        puts "Navigate to Phone Numbers -> Manage -> Active Numbers and find the phone number #{Twilio::Rails.config.default_outgoing_phone_number}."
        puts ""

        if Twilio::Rails.config.phone_trees.all.length == 0
          puts "You cannot yet configure `Voice & Fax' because There are no phone trees registered in this application."
          puts "Register them in the `config/initializers/twilio_rails.rb` file if you want to handle phone calls, and run this task again to help configure Twilio."
        else
          puts "Under 'Voice & Fax' set 'A CALL COMES IN' to 'Webhook' with #{ http_methods } and one of the following URLs:"
          Twilio::Rails.config.phone_trees.all.each do |name, tree|
            puts "  #{tree.inbound_url}"
          end
          puts ""
          puts "Under 'Voice & Fax' set 'CALL STATUS CHANGES' to following URL:"
          puts "  #{ ::Twilio::Rails.config.host }#{ ::Twilio::Rails::Engine.routes.url_helpers.phone_status_path(format: :xml) }"
        end

        puts ""
        puts "Under 'Messaging' set 'A MESSAGE COMES IN' to 'Webhook' with #{ http_methods } and the following URL:"
        puts "  #{ ::Twilio::Rails.config.host }#{ ::Twilio::Rails::Engine.routes.url_helpers.sms_message_path(format: :xml) }"

        if Twilio::Rails.config.sms_responders.all.length == 0
          puts "There are no SMS responders registered so they will not be handled."
          puts "Register them in the `config/initializers/twilio_rails.rb` file if you want to handle SMS messages."
        end
      end
    end
  end
end
