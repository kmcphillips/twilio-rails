# frozen_string_literal: true

FactoryBot.define do
  factory :phone_call, class: ::Twilio::Rails.config.phone_call_class do
    number { "+12048005721" }
    direction { "inbound" }
    from_number { "+16135551234" }
    from_city { "OTTAWA" }
    from_province { "ON" }
    from_country { "CA" }
    sid { "CA5073183d7484999999999999747bf790" }

    before :create do |phone_call|
      unless phone_call.phone_caller
        phone_call.phone_caller = ::Twilio::Rails.config.phone_caller_class.find_or_initialize_by(phone_number: phone_call.from_number)
      end
    end

    trait :american do
      number { "+16667778888" }
    end

    trait :invalid_number do
      from_number { "+888" }
    end

    trait :international_number do
      from_number { "+31618844555" }
      from_country { "NL" }
      from_city { nil }
      from_province { nil }
    end

    trait :invalid_number do
      from_number { "+5555" }
      from_country { nil }
      from_city { nil }
      from_province { nil }
    end

    trait :inbound do
      direction { "inbound" }
    end

    trait :outbound do
      direction { "outbound" }
      from_city { nil }
      from_province { nil }
      from_country { nil }
    end

    trait :answering_machine do
      answered_by { "machine_start" }
    end

    trait :human do
      answered_by { "human" }
    end

    trait :completed do
      call_status { "completed" }
    end

    trait :no_answer do
      call_status { "no-answer" }
    end
  end
end
