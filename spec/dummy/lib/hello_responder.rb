# frozen_string_literal: true
class HelloResponder < Twilio::Rails::SMS::DelegatedResponder
  def handle?
    matches?(/hello/i)
  end

  def reply
    "Hello to you too!"
  end
end
