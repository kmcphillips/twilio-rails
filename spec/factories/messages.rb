# frozen_string_literal: true

FactoryBot.define do
  factory :message, class: ::Twilio::Rails.config.message_class do
    sid { "SM5073183d7484999999999999747bf790" }
    body { "Oh, hello." }
    status { "delivered" }
    direction { "outbound" }

    sms_conversation

    trait :inbound do
      direction { "inbound" }
      status { nil }
      sid { nil }
    end
  end
end
