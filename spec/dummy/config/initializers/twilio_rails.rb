# frozen_string_literal: true
Twilio::Rails.setup do |config|
  config.account_sid = "ACaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  config.auth_token = "auth-token"
  config.default_outgoing_phone_number = "+15552223333"
  config.host = "https://example.com"
  config.phone_trees.register { ToneRatingTree }
  config.phone_trees.register { FavouriteNumberTree }
end
