# frozen_string_literal: true

module TwilioAPIMocks
  def mock_phone_number_lookup(phone_number, country_code: nil)
    response = Twilio::REST::Lookups::V2::PhoneNumberInstance.new("v2", {"country_code" => country_code}, phone_number: phone_number)
    allow(Twilio::Rails::Client).to receive(:phone_number).with(phone_number).and_return(response)
  end

  def mock_phone_number_lookup_error(phone_number, error: nil)
    error ||= Twilio::REST::TwilioError.new("Test error")
    allow(Twilio::Rails::Client).to receive(:phone_number).with(phone_number).and_raise(error)
  end
end
