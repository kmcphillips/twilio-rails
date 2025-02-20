# frozen_string_literal: true

FactoryBot.define do
  factory :response, class: ::Twilio::Rails.config.response_class do
    prompt_handle { "favourite_number" }

    phone_call

    trait :transcribed do
      transcription { "Hello yes I love this phone number" }
      transcribed { true }
    end
  end
end
