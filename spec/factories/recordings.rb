# frozen_string_literal: true
FactoryBot.define do
  factory :recording, class: ::Twilio::Rails.config.recording_class do
    recording_sid { "REdddddddddddddddddddddddddddddddd" }
    duration { (1..4).to_a.sample.to_s }
    url { "https://api.twilio.com/2010-04-01/Accounts/ACaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/Recordings/REdddddddddddddddddddddddddddddddd" }

    phone_call

    trait :audio do
      after :create do |recording|
        recording.audio.attach(io: StringIO.new("abc123"), filename: "recording.wav", content_type: "audio/wav")
      end
    end
  end
end
