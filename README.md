# Twilio Rails

[![RSpec Tests](https://github.com/kmcphillips/twilio-rails/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/kmcphillips/twilio-rails/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/twilio-rails.svg)](https://badge.fury.io/rb/twilio-rails)

The `twilio-rails` gem is an opinionated Rails engine and a framework for building complex, realtime, stateful phone interactions in Rails without needing to directly interact with the Twilio API or use TwiML. It is not a replacement for the [`twilio-ruby` gem](https://github.com/twilio/twilio-ruby), but is rather built on top of it.

The most powerful ability of this engine is to build phone trees (think of calling customer service and pressing 2 for account information or whatever) using a simple Ruby DSL.

What does this mean in practice? **Call and find out!**

The [`twilio-rails-example`](https://github.com/kmcphillips/twilio-rails-example) app is running here:

* **🇨🇦 Calling from Canada:** 📞 (204) 800-7772
* **🇺🇸 Calling from the US:** 📞 (631) 800-7772
* **Internationally:** [Sorry, not yet supported](https://github.com/kmcphillips/twilio-rails#limitations-and-known-issues)

There is also a more fun but less cleanly organized [`dial-a-haiku`](https://github.com/kmcphillips/dial-a-haiku) running here:
* **🇨🇦 Calling from Canada:** 📞 (249) 444-2458 / (249)44-HAIKU
* **🇺🇸 Calling from the US:** 📞 (341) 444-2458 / (341)44-HAIKU
* **Internationally:** [Sorry, not yet supported](https://github.com/kmcphillips/twilio-rails#limitations-and-known-issues)


## Documentation

On [RubyDoc](https://rubydoc.info/gems/twilio-rails) or [Github pages](https://twilio-rails.kev.cool/).


## Getting started

### Installation

This Engine assumes it is running in a Rails app with a configured database, an ActiveJob provider, a configured ActiveStorage store, and controller sessions enabled.

Begin by adding this line to your Rails application's Gemfile:

```ruby
gem "twilio-rails"
```

After running `bundle`, run the installer:

```sh
bin/rails generate twilio:rails:install
```

There is now a pending migration to create the tables needed for the framework. But before running `bin/rails db:migrate` a development domain needs to be setup and the initializer needs to be configured with values from your Twilio account.


### Local development

Twilio requires a publicly accessible URL to make requests to. When developing locally a tool such as [ngrok](https://ngrok.com/) can expose a local dev server via a publicly available SSL URL. Ngrok has a free tier and is easy to use. [See the install instructions for more information](https://ngrok.com/download). Other forwarding services exist and will work fine as well.

Whatever service, the public URL must be set in the `config/initializers/twilio_rails.rb` file as the `host` value. If this value is not set it will be inferred from `action_controller.default_url_options` if possible. Rails also requires the host to be added to the `config.hosts` list in `application.rb` or `development.rb`:

```ruby
# config/application.rb
config.hosts << "my-ngrok-url.ngrok.io"
```


### Twilio configuration

Twilio will provide the phone number(s) you will use for your phone trees and SMS responders. Begin by creating an account and logging in at [https://console.twilio.com](https://console.twilio.com).

From the dashboard, find the "Account SID" and "Auth token" and copy them into the `config/initializers/twilio_rails.rb` file. Or better yet, use an environment variable or a secrets file to store them.

Next, go to "Phone Numbers -> Manage -> Buy a Number" and buy a phone number. Enter this number into the `config/initializers/twilio_rails.rb` file as well as the `default_phone_number` option.

You can get instructions on configuring the Twilio dashboard for your app by running:

```sh
bin/rails twilio:rails:config
```

This command will give you output tailored to the configuration and handlers in your app.

Phone call handerls should be configured something like:
![Twilio phone tree config](https://user-images.githubusercontent.com/84159/233141680-78fde504-583c-44d1-bf42-bb4058e0e523.png)

And SMS handlers something like:
![Twilio sms config](https://user-images.githubusercontent.com/84159/217126828-9c77ab34-9826-4e7c-bac3-2b893b08d39d.png)


### `twilio-rails` configuration

The install generator will create a `config/initializers/twilio_rails.rb` file with reasonable default values and good documentation of each value and its use. Some are required for the engine to function and are provided by Twilio (`account_sid`, `auth_token`, and `default_outgoing_phone_number`).

The config options are documented inline and can be found:
* [In the initializer `lib/generators/twilio/rails/install/templates/twilio_rails.rb`](lib/generators/twilio/rails/install/templates/twilio_rails.rb)
* [In the `Configuration` class](lib/twilio/rails/configuration.rb)


### Generators

There are generators to produce any required boilerplate. As described in the install steps, there is the installation generator:

```sh
bin/rails generate twilio:rails:install
```

And then there are generators to create phone trees and SMS responders:

```sh
bin/rails generate twilio:rails:phone_tree
```
```sh
bin/rails generate twilio:rails:sms_responder
```

Both are explained in detail below.


### Example app

An example Rails app demonstrating the framework is available at [`twilio-rails-example`](https://github.com/kmcphillips/twilio-rails-example). The seteps to go from new Rails app to running Twilio application are broken down into well documented commits. It's a great place to learn and experiment. It can be run locally with some minimal configuration, or can be reached as a working Twilio app by calling:

* **🇨🇦 Calling from Canada:** 📞 (204) 800-7772
* **🇺🇸 Calling from the US:** 📞 (631) 800-7772
* **Internationally:** [Sorry, not yet supported](https://github.com/kmcphillips/twilio-rails#limitations-and-known-issues)


## How it works

This gem provides the persistence layer, lifecycle management and events, and a DSL for building phone trees and SMS responders. Twilio provides a [`twilio-ruby` gem](https://github.com/twilio/twilio-ruby) for their API and [TwiML](https://www.twilio.com/docs/voice/twiml) to define complex phone and SMS interactions. This gem uses both of these but the user does not need to understand or use either of them directly.

### Models

After running the install generator, it generates five Active Record models with the following relationships:

![model classes](https://user-images.githubusercontent.com/84159/217126823-36a8a8c5-3b4e-4d76-987b-f4c237d6ae2e.png)

The `PhoneCaller` is the individual making a phone call, uniquely identified by their phone number.

The `PhoneCall` is the record of a single phone call, either inbound or outbound. It is mutable and lifecycle callbacks handle state changes such as call length, call status, if it was answered or not, answering machine detection, etc.. Every phone call is mapped to exactly one phone tree, discussed in detail below, which directs using ruby how each interaction with the caller is handled.

A phone call has many `Response` records. Each interaction with the caller is a response, which is also mutable and lifecycle managed. Responses are stored in order and are the log of every step of the phone call. Responses contain user input, if any was asked for, such as digit presses, voice input, and transcriptions.

An `SMSConversation` is the record of a series of SMS messages exchanged with a phone caller. Each conversation has many `Message` records, flagged as either inbound or outbound. The full contents of the messages are stored in in the DB. Messages are handled based on responders, discussed in detail below.

Any and all of these models can be extended with extra fields and any logic required by the implementing application. They can also be named differently and configured in the initializer.


### Phone trees

A phone tree is a subclass of [`Twilio::Rails::Phone::BaseTree`](lib/twilio/rails/phone/base_tree.rb) and provides a ruby DSL for defining how a phone call will be handled. See the documentation for full details.

Start by running the generator to create a new phone tree in `app/twilio/phone_trees/documentation_example_tree.rb`:

```sh
bin/rails generate twilio:rails:phone_tree DocumentationExampleTree
```

Regardless of inbound or outbound call, the entrypoint of a phone tree is the `greeting`:

```ruby
class DocumentationExampleTree < Twilio::Rails::Phone::BaseTree
  greeting message: "Hello!",
    prompt: :thank_you_for_calling
```

A `greeting` can provide some kind of `message:` and must provide a `prompt:`. A phone tree is a series of named `prompt`s that are jumped to by name to control the flow of the call. In this example, following the greeting control of the call moves to the `thank_you_for_calling` prompt:

```ruby
prompt :thank_you_for_calling,
  message: "Thank you for calling.",
  after: :hold_music
```

Any `message:` string as text will be read to the caller using Twilio's [Text-To-Speech voice synthesis](https://www.twilio.com/docs/voice/twiml/say/text-speech). Twilio allows the choice between several voices, including Amazon Polly voices. The voice can be set for the entire tree or for individual prompts.

```ruby
voice "man"

prompt :polly_demo,
  message: { say: "I am a Polly voice.", voice: "Polly.Matthew-Neural" },
  after: :hold_music
```

Any `message:` can also accept a `Hash` instead of a `String`:

* `{ say: "Hello" }` - Text-to-speech using the default or globally configured voice. Equivalent to just passing `"Hello"`.
* `{ say: "Hello", voice: "man" }` - Text-to-speech using the specified voice.
* `{ play: "https://example.com/audio.mp3" }` - Play a `wav` or `mp3` audio file from a URL.
* `{ pause: 1 }` - Pause silently for the specified number of seconds.

A `message:` can also be an `Array` which contains any number of the above hashes and strings, which will be passed to Twilio in order.

```ruby
prompt :musical_interlude,
  message: [
    { say: "Please listen to this music.", voice: "Polly.Salli" },
    { play: "https://example.com/musical_interlude.mp3" },
    { pause: 1 }
    "We hope you enjoyed this music.",
  ],
  after: :time_of_day
```

And finally, a `message:` can be a `Proc` which will be called with the previous `Response` object and can return any of the above. Nearly any part of a phone tree can be a `Proc` which can be used to make the tree dynamic and interactive.

```ruby
prompt :time_of_day,
  message: ->(response) { "The time is #{Time.now.strftime("%l:%M %p")}." },
  after: {
    prompt: :last_prompt,
    message: ->(response) { "All is well." }
  }
```

The `after:` option can be a `Hash` rather than just a symbol. If it is a hash it accepts a `prompt:` key which is the same as just passing a symbol. It also accepts a `message:` which supports all of the above options, including a `Proc`. Though in this case it will be called with the current `Response` object, not the previous one.

```ruby
prompt :last_prompt,
  after: {
    message: "Have a good day. Goodbye.",
    hangup: true
  }
```

The `after:` option can also accept a `hangup:` key which will hang up the call after the message is read. This is useful for the last prompt in a tree. The `after:` must provide either the next prompt or a hangup, not both. The entire `after:` can also be a `Proc` with the current response object.

```ruby
prompt :maybe_last_prompt,
  after: ->(response) {
    if MyServiceObject.should_hangup?(response)
      { message: "Sorry, this call must now end.", hangup: true }
    else
      :main_menu
    end
  }
```

This is starting to show how using `Proc`s a phone tree can be highly dynamic and interactive. Each `Response` is saved to the database automatically, and associated to the `PhoneCall` in order. The `Proc` can make calls into the Rails app and do any kind of complex logic to determine the next step in the call. Just be aware that raising an exception or returning an invalid value will cause Twilio to error and for the call to end. Also keep in mind that Twilio will end the call if the response takes too long.

The final key that `prompt` accepts is `gather:`. This is used to collect digits from the keypad, or speech/voice audio. A `gather:` is optional and will be inserted between the `message:` if any and the `after:`.

```ruby
prompt :rate_your_experience,
  message: "Please rate your experience on a scale of 1 to 5."
  gather: {
    type: :digits,
    timeout: 5,
    number: 1,
    interrupt: true
  },
  after: ->(response) {
    if response.integer_digits.blank?
      {
        message: "Sorry, we did not get your rating. You can enter using the number keys on your phone",
        prompt: :rate_your_experience
      }
    elsif response.integer_digits < 1 || response.integer_digits > 5
      {
        message: "Sorry, your rating must be between 1 and 5.",
        prompt: :rate_your_experience
      }
    else
      {
        message: "You have given a rating of #{ response.integer_digits }. Thank you. Goodbye.",
        hangup: true
      }
    end
  }
```

The `gather:` for `type: :digits` pauses after the message for `timeout:` number of seconds, defaulting to 5, and waits for the caller to type in `number:` number of digits, defaulting to 1. The digits, if any pressed, will be stored on the `Response` and this can be used in the `after:` to determine the next step in the call. The `interrupt:` boolean option, default `false`, dictates if pressing a digit will interrupt the message being played, or if the gather will not gather until the message has completed playing. To tie it together, the above example uses an [accessor method on `Response`](lib/twilio/rails/models/response.rb) to get the digits as an integer, and takes an action based on some basic data validation. If the response is not valid, the same prompt is repeated to the caller. If a digit is pressed before the message is finished playing, the message will stop, the digit will be stored, and move right to the `after`.

The `gather:` can also accept `type: :voice` which will record the caller's voice for `length:` number of seconds, defaulting to 10.

```ruby
prompt :record_your_feedback,
  message: "Please leave us a message with your feedback, and press the pound key when you are done.",
  gather: {
    type: :voice,
    length: 30,
    transcribe: true,
    profanity_filter: true
  },
  after: {
    message: "Thank you for your feedback. Goodbye.",
    hangup: true
  }
```

The above `gather:` with `type: :voice` example will finish reading the message and then record the phone caller's speech for 30 seconds or until they press the `#` pound key. The phone tree will then immediately execute the `after:`, while the framework continues to handle the audio recording asynchronously. When Twilio makes it available, the audio file of the recording will be downloaded and stored as an ActiveStorage attachment in a `Recording` model as `response.recording`. If the `transcribe:` option is set to `true`, the voice in the recording will also attempt to be transcribed as text and stored as `response.transcription`. Importantly though, **neither are guaranteed to arrive or will arrive immediately**. In practice they both usually arrive within a few seconds, but can sometimes be blank or missing if the caller is silent or garbled. There is a cost to transcription so it can be disabled, and the `profanity_filter:` defaults to false and will just *** out any profanity in the transcription.

Finally, the `gather:` can also accept `type: :speech` which is a specialzed model designed to identify voice in realtime. It will provide the `response.transcription` field immediately, making it available in the `after:` proc or in the next prompt. But the tradeoffs are that it does not provide a recording, there is a time gap of a few seconds between prompts, and it is more expensive. See the [Twilio documentation for specifics](https://www.twilio.com/docs/voice/twiml/gather#speechmodel). The keys it expects match the documentation, `speech_model:`, `speech_timeout:`, `language:` (defaults to "en-US"), and `enhanced:` (defaults to false).

```ruby
prompt :what_direction_should_we_go,
  message: "Which cardinal direction should we go?",
  gather: {
    type: :speech,
    language: "en-US",
    enhanced: true,
    speech_model: "numbers_and_commands",
    speech_timeout: "auto",
  },
  after: ->(response) {
    if response.transcription.blank?
      {
        message: "Sorry, we did not get your response. Please try again.",
        prompt: :what_direction_should_we_go,
      }
    elsif response.transcription_matches?("north", "south", "east", "west")
      MyCommandObject.move(response.transcription)

      {
        message: "Moving #{ response.transcription }.",
        hangup: true
      }
    else
      {
        message: "Sorry, we did not understand your response.",
        prompt: :what_direction_should_we_go,
      }
    end
  }
```

To inspect the implementation and get further detail, most of the magic happens in [`Twilio::Rails::Phone::Tree`](lib/twilio/rails/phone/tree.rb) and the operations under [`Twilio::Rails::Phone::Twiml`](app/operations/twilio/rails/phone/twiml/) where the DSL is defined and then converted into [TwiML](https://www.twilio.com/docs/voice/twiml).


### Make an outgoing phone call

An outgoing phone call may be started from any valid phone tree and any configured Twilio phone number via the [`Twilio::Rails::Phone::StartCallOperation`](app/operations/twilio/rails/phone/start_call_operation.rb). This starts the asynchronous process of making the call. It will return the DB phone call instance which will be updated with the status of the call.

```ruby
Twilio::Phone::StartCallOperation.call(
  tree: Twilio::Rails.config.phone_trees.for("your_tree_name"),
  to: "+155566677777", # or an instance of Twilio::Rails::PhoneNumber
  from: Twilio::Rails.config.default_outgoing_phone_number # optional and defaults to this value
)
```


### SMS responders

> [!IMPORTANT]
> Due to how Twilio makes API calls into the application for SMS messages, SMS responders require Rails sessions to be enabled and setup in order to handle SMS messages.

Twilio provides a hook for incoming SMS messages and can send SMS messages to any phone number. This gem provides a simple method for handling SMS conversations, though it does not provide a full stateful tree structure.

An SMS responder is a subclass of [`Twilio::Rails::SMS::DelegatedResponder`](lib/twilio/rails/sms/delegated_responder.rb). Any number of responders may be added to the app provided they are registered in the initializer with `config.sms_responders.register { MyResponderClass }`.

The responder class will be initialized with the `message` and `sms_conversation` local variables set, and must implement two methods:
* `handle?`: Return true if this handler handles the given message, false if it does not.
* `reply`: A string to reply to the message with, or `nil` if the message is handled and no response should be sent.

All registered responders will be visited in order and the first one to return a truthy value from `#handle?` will handle the message and no further responders will be called. If all `#handle?` methods return false than the incoming message is ignored.

The `sms_conversation` variable is an instance of the implementor of `Twilio::Rails::Models::SMSConversation` and contains the full history of the conversation with this phone caller, and can be used to determine the next step in the conversation. These models can also be extended to add any required application level fields and logic.


### Send an outgoing SMS message

An out going SMS message may be sent via the [`Twilio::Rails::SMS::SendOperation`](app/operations/twilio/rails/sms/send_operation.rb). This will send the message and start a conversation, storing all messages and replies in the DB:

```ruby
Twilio::Rails::SMS::SendOperation.call(
  phone_caller_id: phone_caller.id,
  messages: ["Hello world!"], # an array of strings, each one will be sent as a separate message in sequence
  from_number: Twilio::Rails.config.default_outgoing_phone_number # optional and defaults to this value
)
```

Since the operation assumes a phone caller, it can first be created and/or retrieved by calling:

```ruby
phone_caller = Twilio::Rails::FindOrCreatePhoneCallerOperation.call(phone_number: "+155566677777")
```


### Errors

All errors are subclasses of [`Twilio::Rails::Error`](lib/twilio/rails.rb). They are grouped under [`Twilio::Rails::Phone::Error`](lib/twilio/rails/phone.rb) and [`Twilio::Rails::SMS::Error`](lib/twilio/rails/sms.rb), and then further specialized from there.

There are a few places where exceptions are notified from inside the framework using `::Rails.error.report`. They are never rescued or handled. See the [Rails documentation](https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html) for how to use the error reporter.


### The rest of the documentation

Anything not covered in this documentation is probably documented on the classes and method calls in the application. Probably the most interesting and useful places to look are:

* [lib/twilio/rails/models](lib/twilio/rails/models)
* [app/operations](app/operations)


## Limitations and known issues

This framework was extracted from a larger project. There are some assumptions built in that are limitations of the current implementation. Please feel free to PR improvements! But for now, known limitations are:

* Only North American phone numbers are supported, 1 plus 10 digits (`+155566677777`).
  * If a phone call whose number is not of the above format is received it is not even persisted or handled.
* Some North American assumptions of "day" are probably hidden in a couple places.
* Only production tested with MySQL and SQLite, but should work with Postgres. Assumes `utf8mb4` encoding in MySQL, but the migration does not specify it in order to support other DBs.
* Only production tested with Sidekiq, but any ActiveJob provider should work.
* There is no support for domain level events or observers. This means hooks need to be implemented using active record model callbacks, which is opaque, fragile, and confusing. In future the framework could define and trigger named events based on lifecycle.
* SMS handling is pretty simple and pattern matching based. This is not an implementation of a full chat bot. Other better frameworks exist for that. This could probably be completely rebuilt to work in a similar way where a phone number is bound to a responder by name, rather than each one implementing `handle?`.
  * The `DelegatedResponder#reply` method assumes a single `String` message, but probably should also or by default support an array of strings.
* Generators do not generate tests, but should look at the generator `test_framework` config and produce tests or specs for the created classes.
* Not all Twilio TwiML features are supported. Many though are easy to add flags that are just passed through, and are easy to add.
  * The `gather:` should support `hints:` and some other config options.
* Some documentation is missing in:
  * Controller actions.


## Contributing

PRs welcome! I will help you. Please do not hesitate to open PRs or issues if a feature is missing or if you encounter a bug.

To get started, fork the repo and clone it. The `.ruby-version` assumes Ruby 3.2.0 but this can easily be changed.

Run `bundle install` to install dependencies. A console can be started with `bin/rails c`. The tests can be run with `bundle exec rspec`.

No PR will be accepted without test coverage. Please add tests for any new features or bug fixes.

Any change must also be tested against [the example app](https://github.com/kmcphillips/twilio-rails-example), but this is not an automated process. See the documentation in the example app for more information.
