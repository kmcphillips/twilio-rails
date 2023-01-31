# Implements all the routes that Twillio will call to manage the lifecycle of phone calls and SMS messages. See the
# {README.md} for detailed instructions on how to configure the Twilio dashboard to call these routes.
Twilio::Rails::Engine.routes.draw do
  match "phone/receive_recording/:response_id", to: "phone#receive_response_recording", as: :phone_receive_recording, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/transcribe/:response_id", to: "phone#transcribe", as: :phone_transcribe, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/status", to: "phone#status", as: :phone_status, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/:tree_name/inbound", to: "phone#inbound", as: :phone_inbound, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/:tree_name/outbound", to: "phone#outbound", as: :phone_outbound, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/:tree_name/prompt/:response_id", to: "phone#prompt", as: :phone_prompt, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/:tree_name/prompt_response/:response_id", to: "phone#prompt_response", as: :phone_prompt_response, via: ::Twilio::Rails.config.controller_http_methods
  match "phone/:tree_name/timeout/:response_id", to: "phone#timeout", as: :phone_timeout, via: ::Twilio::Rails.config.controller_http_methods

  match "sms/message", to: "sms#message", as: :sms_message, via: ::Twilio::Rails.config.controller_http_methods
  match "sms/status", to: "sms#status", as: :sms_status, via: ::Twilio::Rails.config.controller_http_methods
  match "sms/status/:message_id", to: "sms#status", as: :sms_status_message, via: ::Twilio::Rails.config.controller_http_methods
end
