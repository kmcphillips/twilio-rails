# frozen_string_literal: true
class FavouriteNumberTree < Twilio::Rails::Phone::BaseTree
  voice "male"

  final_timeout_message(say: "Sorry we have lost you.")

  invalid_phone_number ->(response) {
    [
      "Thank you for calling.",
      { say: "But you are calling from outside North America."},
    ]
  }

  greeting message: ->(response) { "Hello, and thank you for calling!" },
    prompt: :favourite_number

  prompt :favourite_number,
    message: [
      "Using the keypad on your touch tone phone...",
      { pause: 2 },
      { say: "please enter your favourite number.", voice: "Polly.Joanna" },
    ],
    gather: {
      type: :digits,
      timeout: 10,
      number: 1,
    },
    after: {
      prompt: :second_favourite_number,
      message: ->(response) { "Thank you for your selection." }
    }

  prompt :second_favourite_number,
    message: { say: "In the case that your favourite number is not available, please enter your second favourite number." },
    gather: {
      type: :digits,
      timeout: 10,
      number: 1,
    },
    after: ->(response) {
      prev_fav = response.phone_call.responses.completed.find_by(prompt_handle: "favourite_number")

      if !prev_fav
        { hangup: true, message: "Invalid input" }
      elsif prev_fav.digits == response.digits
        {
          prompt: :second_favourite_number,
          message: "Sorry, but your second favourite number cannot be the same as your first.",
        }
      else
        {
          prompt: :favourite_number_reason,
          message: "Your favourite numbers have been recorded. The numbers #{response.digits} and #{prev_fav.digits}",
        }
      end
    }

  prompt :favourite_number_reason,
    message: ->(response) { "Now, please state after the tone your reason for picking those numbers as your favourites." },
    gather: {
      type: :voice,
      length: 4,
      transcribe: true,
    },
    after: {
      hangup: true,
      message: "Thank you for your input! We have made a note of your reasons. Your opinion is important to us and will be disregarded.
        We appreciate your business.",
    }

  prompt :favourite_number_speech,
    message: ->(response) { "Can you please state your favourite number after the tone?" },
    gather: {
      type: :speech,
      timeout: 5,
      language: "en-CA",
      enhanced: true,
      speech_timeout: "auto",
      speech_model: :phone_call,
      profanity_filter: true,
    },
    after: {
      hangup: true,
      message: "Thank you for speaking that number.",
    }
end
