# frozen_string_literal: true
class ToneRatingTree < Twilio::Rails::Phone::BaseTree
  voice "female"

  greeting message: "Hello. Please listen to the following tone:",
    prompt: :play_first_tone

  prompt :play_first_tone,
    message: ->(response) { macros.play_public_file("A440.wav") }, # TODO: this needs to map to the correct file in the dummy public folder
    after: {
      prompt: :first_tone_feedback,
      message: "Thank you for listening to that tone.",
    }

  prompt :first_tone_feedback,
    message: [
      "In remembering this tone:",
      ->(response) { { play: macros.public_file("A440.wav") } },
      { say: "On a scale from zero to six, please rate how much you enjoyed this tone" },
    ],
    gather: {
      type: :digits,
      timeout: 10,
      number: 1,
      finish_on_key: "",
    },
    after: ->(response) {
      if response.timeout?
        {
          prompt: :first_tone_feedback,
          message: "Sorry, we didn't get a response.",
        }
      elsif response.digits.present? && response.digits.to_i <= 6
        {
          hangup: true,
          message: "Thank you for your rating of #{response.digits} for this tone. Your feedback is important. Goodbye.",
        }
      else
        {
          prompt: :first_tone_feedback,
          message: "Sorry, you have entered an invalid rating of #{response.digits}",
        }
      end
    }

  prompt :interrupt_feedback,
    message: ->(response) {
      [
        ->(response) { "first say" },
        "second say",
        { play: "https://example.com/wav.mp3" },
        { say: "third say" },
      ]
    },
    gather: {
      type: :digits,
      timeout: 20,
      number: 2,
      interrupt: true,
    },
    after: {
      message: "Thank you!",
      hangup: true,
    }

  unanswered_call ->(phone_call) {
    phone_call.touch # This is a placeholder action to test with
  }
end
