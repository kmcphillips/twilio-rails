# frozen_string_literal: true

FactoryBot.define do
  factory :sms_conversation, class: ::Twilio::Rails.config.sms_conversation_class do
    number { "+12048005721" }
    from_number { "+16135551234" }
    from_city { "OTTAWA" }
    from_province { "ON" }
    from_country { "CA" }
  end
end
