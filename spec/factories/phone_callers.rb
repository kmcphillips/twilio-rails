# frozen_string_literal: true
FactoryBot.define do
  factory :phone_caller, class: ::Twilio::Rails.config.phone_caller_class do
    phone_number { "+16135551234" }

    trait :american_number do
      phone_number { "+12135550000" }
    end

    trait :international_number do
      phone_number { "+31618844555" }
    end

    trait :complete do
      name { "Valued Customer" }
    end

    trait :another_number do
      phone_number { "+12045556666" }
    end

    trait :another_american_number do
      phone_number { "+12135551111" }
    end
  end
end
