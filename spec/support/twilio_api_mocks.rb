# frozen_string_literal: true

module TwilioAPIMocks
  def mock_phone_number_country_code_lookup(phone_number, country_code:)
    allow(Twilio::Rails::Client).to receive(:country_code).with(phone_number).and_return(country_code)
  end

  def mock_phone_number_country_code_lookup_error(phone_number, error: nil)
    error ||= Twilio::REST::TwilioError.new("Test error")
    allow(Twilio::Rails::Client).to receive(:country_code).with(phone_number).and_raise(error)
  end
end
