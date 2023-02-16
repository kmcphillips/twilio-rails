# frozen_string_literal: true
class ToneRatingTree < Twilio::Rails::Phone::BaseTree
  voice "female"

  greeting message: "Hello. Please listen to the following tone:",
    prompt: :play_first_tone

  prompt :play_first_tone,
    message: ->(response) { macros.play_public_file("A440.wav") },
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
      prompt: :speech_with_defaults,
    }

  prompt :speech_with_defaults,
    message: "Please say something",
    gather: {
      type: :speech,
    },
    after: :with_ssml_block

  prompt :with_ssml_block,
    message: macros.say { |say|
      say.break(strength: 'x-weak', time: '100ms')
      say.emphasis(words: 'Words to emphasize', level: 'moderate')
      say.p(words: 'Words to speak')
      say.add_text('aaaaaa')
      say.phoneme('Words to speak', alphabet: 'x-sampa', ph: 'pɪˈkɑːn')
      say.add_text('bbbbbbb')
      say.prosody(words: 'Words to speak', pitch: '-10%', rate: '85%', volume: '-6dB')
      say.s(words: 'Words to speak')
      say.say_as('Words to speak', interpretAs: 'spell-out')
      say.sub('Words to be substituted', alias: 'alias')
      say.w(words: 'Words to speak')
    },
    after: {
      hangup: true
    }

  unanswered_call ->(phone_call) {
    phone_call.touch # This is a placeholder action to test with
  }
end
