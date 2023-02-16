# frozen_string_literal: true
module Twilio
  module Rails
    module Phone
      # Implementation class for a phone tree. See {Twilio::Rails::Phone::BaseTree} for detailed documentation.
      class Tree
        attr_reader :name, :prompts, :config
        attr_accessor :greeting, :unanswered_call

        def initialize(tree_name)
          @name = tree_name.to_s
          raise Twilio::Rails::Phone::InvalidTreeError, "tree name cannot be blank" unless name.present?

          @prompts = {}.with_indifferent_access
          @config = {}.with_indifferent_access

          # defaults
          @config[:voice] = "male"
          @config[:final_timeout_message] = "Goodbye."
          @config[:final_timeout_attempts] = 3
        end

        # The fully qualified URL for the tree used by Twilio to make outbound calls.
        #
        # @return [String] The outbound URL for the phone tree.
        def outbound_url
          "#{ ::Twilio::Rails.config.host }#{ ::Twilio::Rails::Engine.routes.url_helpers.phone_outbound_path(tree_name: name, format: :xml) }"
        end

        # The fully qualified URL for the tree used by Twilio to be configured in the dashboard.
        #
        # @return [String] The inbound URL for the phone tree.
        def inbound_url
          "#{ ::Twilio::Rails.config.host }#{ ::Twilio::Rails::Engine.routes.url_helpers.phone_inbound_path(tree_name: name, format: :xml) }"
        end

        class Prompt
          attr_reader :name, :messages, :gather, :after

          def initialize(name:, message:, gather:, after:)
            @name = name&.to_sym
            raise Twilio::Rails::Phone::InvalidTreeError, "prompt name cannot be blank" if @name.blank?

            @messages = if message.is_a?(Proc)
              message
            else
              Twilio::Rails::Phone::Tree::MessageSet.new(message)
            end

            @gather = Twilio::Rails::Phone::Tree::Gather.new(gather) if gather.present?
            @after = Twilio::Rails::Phone::Tree::After.new(after)
          end
        end

        class After
          attr_reader :messages, :prompt, :proc

          def initialize(args)
            case args
            when Symbol, String
              @prompt = args.to_sym
            when Proc
              @proc = args
            when Hash
              args = args.with_indifferent_access
              @prompt = args[:prompt]&.to_sym
              @hangup = !!args[:hangup]

              @messages = if args[:message].is_a?(Proc)
                args[:message]
              else
                Twilio::Rails::Phone::Tree::MessageSet.new(args[:message])
              end

              raise Twilio::Rails::Phone::InvalidTreeError, "cannot have both prompt: and hangup:" if @prompt && @hangup
              raise Twilio::Rails::Phone::InvalidTreeError, "must have either prompt: or hangup:" unless @prompt || @hangup
            else
              raise Twilio::Rails::Phone::InvalidTreeError, "cannot parse :after from #{args.inspect}"
            end
          end

          def hangup?
            !!@hangup
          end
        end

        class Gather
          attr_reader :type, :args

          def initialize(args)
            case args
            when Proc
              @proc = args
            when Hash
              @args = args.with_indifferent_access
              @type = @args.delete(:type)&.to_sym

              raise Twilio::Rails::Phone::InvalidTreeError, "gather :type must be :digits, :voice, or :speech but was #{@type.inspect}" unless [:digits, :voice, :speech].include?(@type)

              if digits?
                @args[:timeout] ||= 5
                @args[:number] ||= 1
              elsif voice?
                @args[:length] ||= 10
                @args[:beep] = true unless @args.key?(:beep)
                @args[:transcribe] = false unless @args.key?(:transcribe)
                @args[:profanity_filter] = false unless @args.key?(:profanity_filter)
              elsif speech?
                @args[:language] ||= "en-US"
              else
                raise Twilio::Rails::Phone::InvalidTreeError, "gather :type must be :digits, :voice, or :speech but was #{@type.inspect}"
              end
            else
              raise Twilio::Rails::Phone::InvalidTreeError, "cannot parse :gather from #{args.inspect}"
            end
          end

          def digits?
            type == :digits
          end

          def voice?
            type == :voice
          end

          def speech?
            type == :speech
          end

          def interrupt?
            if @args.key?(:interrupt)
              !!@args[:interrupt]
            else
              false
            end
          end
        end

        class Message
          attr_reader :value, :voice, :block

          def initialize(say: nil, play: nil, pause: nil, voice: nil, &block)
            @say = say.presence
            @play = play.presence
            @pause = pause.presence.to_i
            @pause = nil if @pause == 0
            @voice = voice.presence
            @block = block if block_given?

            raise Twilio::Rails::Phone::InvalidTreeError, "must only have one of say: play: pause:" if (@say && @play) || (@say && @pause) || (@play && @pause)
            raise Twilio::Rails::Phone::InvalidTreeError, "say: must be a string or proc" if @say && !(@say.is_a?(String) || @say.is_a?(Proc))
            raise Twilio::Rails::Phone::InvalidTreeError, "play: must be a string or proc" if @play && !(@play.is_a?(String) || @play.is_a?(Proc))
            raise Twilio::Rails::Phone::InvalidTreeError, "play: be a valid url but is #{ @play }" if @play && @play.is_a?(String) && !@play.match(/^https?:\/\/.+/)
            raise Twilio::Rails::Phone::InvalidTreeError, "pause: must be over zero but is #{ @pause }" if @pause && @pause <= 0
            raise Twilio::Rails::Phone::InvalidTreeError, "block is only valid for say:" if block_given? && (@play || @pause)
          end

          def say?
            !!(@say || @block)
          end

          def play?
            !!@play
          end

          def pause?
            !!@pause
          end

          def value
            @say || @play || @pause
          end
        end

        class MessageSet
          include Enumerable

          def initialize(set)
            @messages = []

            # This whole chunk here feels like an incorrect level of abstraction. That it should be the caller's responsbiility
            # to pass in the contents of `message:` and not a hash with `message:` as a key. But maybe it's ok to do it once
            # here so the callsites can be cleaner passthroughs without doing the checks over and over.
            if set.is_a?(Hash)
              set = set.symbolize_keys
              if set.key?(:message)
                raise Twilio::Rails::Phone::InvalidTreeError, "MessageSet should never receive a hash with any key other than :message but received #{ set }" if set.keys != [:message]
                set = set[:message]
              end
            end

            set = [set] unless set.is_a?(Array)
            set.each do |message|
              next nil if message.blank?

              if message.is_a?(Twilio::Rails::Phone::Tree::Message)
                @messages << message
              elsif message.is_a?(Proc)
                @messages << message
              elsif message.is_a?(String)
                @messages << Twilio::Rails::Phone::Tree::Message.new(say: message)
              elsif message.is_a?(Hash)
                @messages << Twilio::Rails::Phone::Tree::Message.new(**message.symbolize_keys)
              else
                raise Twilio::Rails::Phone::InvalidTreeError, "message value #{ message } is not valid"
              end
            end
          end

          def each(&block)
            @messages.each(&block)
          end

          def length
            @messages.count
          end

          def first
            @messages.first
          end

          def last
            @messages.last
          end
        end
      end
    end
  end
end
