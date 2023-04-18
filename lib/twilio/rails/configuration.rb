# frozen_string_literal: true
module Twilio
  module Rails
    class Configuration
      # Raised in initialization if the configuration is invalid.
      class Error < StandardError ; end

      def initialize
        @finalized = false
        @setup = false

        @default_outgoing_phone_number = nil
        @logger = ::Rails.logger
        @account_sid = nil
        @auth_token = nil
        @spam_filter = nil
        @exception_notifier = nil
        @attach_recordings = true
        @yes_responses = [ "yes", "accept", "ya", "yeah", "true", "ok", "okay" ]
        @no_responses = [ "no", "naw", "nah", "reject", "decline", "negative", "not", "false" ]
        @message_class_name = "Message"
        @message_class = nil
        @phone_call_class_name = "PhoneCall"
        @phone_call_class = nil
        @phone_caller_class_name = "PhoneCaller"
        @phone_caller_class = nil
        @sms_conversation_class_name = "SMSConversation"
        @sms_conversation_class = nil
        @response_class_name = "Response"
        @response_class = nil
        @recording_class_name = "Recording"
        @recording_class = nil
        @phone_trees = PhoneTreeRegistry.new
        @sms_responders = SMSResponderRegistry.new
        @host = if ::Rails.configuration&.action_controller&.default_url_options
          "#{ ::Rails.configuration.action_controller.default_url_options[:protocol] }://#{ ::Rails.configuration.action_controller.default_url_options[:host] }"
        else
          nil
        end
        @controller_http_methods = [:get, :post]
        @include_phone_macros = []
      end

      # This is the phone number that will be used to send SMS messages or start Phone Calls. It must be first configured
      # and purchased in the Twilio dashboard, then entered here. The format must be "+15556667777". In most applications it
      # is probably the only number, but in more complex applications it is the "main" or default number. It is used when
      # the phone number is not specified and the number otherwise cannot be intelligently guessed or inferred.
      #
      # @return [String] the default outgoing phone number formatted as "+15555555555"
      attr_accessor :default_outgoing_phone_number

      # The logger used by the framework. Defaults to `Rails.logger`. It cannot be `nil`, so to disable framework
      # logging explicitly set it to `Logger.new(nil)`.
      #
      # @return [Logger] the logger used by the framework.
      attr_accessor :logger

      # The account SID used to authenticate with Twilio. This should be set from an environment variable or from
      # somewhere like `Rails.credentials`.
      #
      # @return [String] the account SID used to authenticate with Twilio.
      attr_accessor :account_sid

      # The account auth token used to authenticate with Twilio. his should be set from an environment variable or from
      # somewhere like `Rails.credentials`.
      #
      # @return [String] the account auth token used to authenticate with Twilio.
      attr_accessor :auth_token

      # Allows SMS messages to be filtered at source if they appear to be spam. This is an optional callable that is run
      # with raw params from Twilio on each request. If the callable returns `true` it will prevent the message from
      # being processed. This is useful for filtering out messages that are obviously spam. Setting this to `nil` will
      # disable the filter and is the default.
      #
      # @return [Proc] a proc that will be called to filter messages, or `nil` if no filter is set.
      attr_accessor :spam_filter

      # A proc that will be called when an exception is raised in certain key points in the framework. This will never
      # capture the exception, it will raise regardless, but it is a good spot to send an email or notify in chat
      # if desired. The proc needs to accept `(exception, message, context, exception_binding)` as arguments. The
      # default is `nil`, which means no action will be taken.
      #
      # @return [Proc] a proc that will be called when an exception is raised in certain key points in the framework.
      attr_accessor :exception_notifier

      # Controls if recordings will be downloaded and attached to the `Recording` model in an ActiveStorage attachment.
      # This is `true` by default, but can be set to `false` to disable all downloads. It can also be set to a `Proc` or
      # callable that will receive the `Recording` instance and return a boolean for this specific instance. A typical
      # usage would be to delegate to the model or a business logic process to determine if the recording should be
      # downloaded.
      #
      # @example
      #   Twilio::Rails.config.attach_recordings = ->(recording) { recording.should_attach_audio? }
      #
      # @return [true, false, Proc] a boolean or a proc that will be called to return a boolean to determine if reordings will be downloaded.
      attr_accessor :attach_recordings

      # A list of strings to be interpreted as yes or acceptance to a question.
      #
      # @return [Array<String>] a list of strings to be interpreted as yes or acceptance to a question.
      attr_accessor :yes_responses

      # A list of strings to be interpreted as no or rejection to a question.
      #
      # @return [Array<String>] a list of strings to be interpreted as no or rejection to a question.
      attr_accessor :no_responses

      # The name of the model classes, as strings, that this application uses to represent the concepts stored in the DB.
      # The generators will generate the models with the default names below, but they can be changed as the application
      # may need.
      #
      # @return [String] the name of the model class defined in the Rails application.
      attr_accessor :phone_caller_class_name, :phone_call_class_name, :response_class_name,
        :sms_conversation_class_name, :message_class_name, :recording_class_name
      # @return [Class] the class of the model defined in the Rails application constantized from the string name.
      attr_reader :phone_caller_class, :phone_call_class, :response_class,
        :sms_conversation_class, :message_class, :recording_class

      # A registry of phone tree classes that are used to handle incoming phone calls. Calling `register` will add
      # a responder, and they can be accessed via `all` or `for(name)`. The tree is built by subclassing
      # `Twilio::Rails::Phone::BaseTree` and defining the tree as described in the documentation.
      #
      # @return [PhoneTreeRegistry] a registry of phone tree classes that are used to handle incoming phone calls.
      attr_reader :phone_trees

      # A registry of SMS responder classes that are used to handle incoming SMS messages. Calling `register` will add
      # a responder, and they can be accessed via `all` or `for(name)`. The class must either be a subclass
      # of `Twilio::Rails::SMS::DelegatedResponder` or implement the same interface. Responders are evaluated in the
      # order they are registered.
      #
      # @return [SMSResponderRegistry] a registry of SMS responder classes that are used to handle incoming messages.
      attr_reader :sms_responders

      # The default protocol and host used to generate URLs for Twilio to call back to. Defaults to what is defined
      # by `Rails` using `default_url_options`.
      #
      # @return [String] the host and protocol where Twilio can reach the application, formatted "https://example.com".
      attr_reader :host
      # Sets the host and protocol where Twilio can reach the application, formatted "https://example.com".
      #
      # @param value [String] the host and protocol where Twilio can reach the application, formatted "https://example.com".
      def host=(value)
        @host = if value.is_a?(String)
          value.gsub(/\/$/, "")
        else
          value
        end
      end

      # The {#host} domain name with the protocol stripped, if the host is set.
      #
      # @return [String] the {#host} domain name.
      def host_domain
        return nil unless host.present?
        value = host.gsub(/\Ahttps?:\/\//, "")
        value = value.gsub(/:\d+\z/, "")
        value
      end

      # The HTTP methods that Twilio will use to call into the app. Defaults to `[:get, :post]` but can be restricted
      # to just `[:get]` or `[:post]`. This must match the configuration in the Twilio dashboard.
      #
      # @return [Array<Symbol>] the HTTP methods used for the routes that Twilio will use to call into the app.
      attr_accessor :controller_http_methods

      # Allows adding a module to be included into the `macros` in the phone tree DSL. This is useful for adding
      # convenience methods specific to the application. It can be called multiple times to add multiple modules.
      # Built in macros can be seen in {Twilio::Rails::Phone::TreeMacros}.
      #
      # @param [Module] mod a module to be included into the `macros` module use in the phone tree DSL.
      # @return [nil]
      def include_phone_macros(mod)
        @include_phone_macros << mod

        if @finalized
          validate!
          until @include_phone_macros.empty?
            Twilio::Rails::Phone::TreeMacros.include(@include_phone_macros.pop)
          end
        end

        nil
      end

      # Uses the {#attach_recordings} configuration to determine if the recording should be downloaded and attached.
      #
      # @return [true, false] If this recording should be downloaded and attached.
      def attach_recording?(recording)
        if attach_recordings.is_a?(Proc) || attach_recordings.respond_to?(:call)
          !!attach_recordings.call(recording)
        else
          !!attach_recordings
        end
      end

      # Flags that the configuration has been setup and should be validated and finalized.
      # If this is not called, the framework will not work, but the Railtie will not prevent
      # the application from starting.
      #
      # @return [nil]
      def setup!
        @setup = true
        nil
      end

      # Validates the configuration and raises an error if it is invalid. This is called after initialization, but is
      # not the finalized configuration. See {.finalize!} for the last step.
      #
      # @return [nil]
      def validate!
        return nil unless @setup
        raise Error, "`default_outgoing_phone_number` must be set" if @default_outgoing_phone_number.blank?
        raise Error, "`default_outgoing_phone_number` must be a String of the format `\"+12223334444\"`" unless @default_outgoing_phone_number.is_a?(String) && @default_outgoing_phone_number.match?(/\A\+1[0-9]{10}\Z/)
        raise Error, "`account_sid` must be set" if @account_sid.blank?
        raise Error, "`auth_token` must be set" if @auth_token.blank?
        raise Error, "`logger` must be set" if @logger.blank?
        raise Error, "`spam_filter` must be callable" if @spam_filter && !@spam_filter.respond_to?(:call)
        raise Error, "`exception_notifier` must be callable" if @exception_notifier && !@exception_notifier.respond_to?(:call)
        raise Error, '`yes_responses` must be an array' unless @yes_responses.is_a?(Array)
        raise Error, '`no_responses` must be an array' unless @no_responses.is_a?(Array)
        raise Error, "`host` #{ @host.inspect } is not a valid URL of the format https://example.com without the trailing slash" unless @host =~ /\Ahttps?:\/\/[a-z0-9\-\.:]+\Z/i
        raise Error, "`controller_http_methods` must be an array containing one or both of `:get` and `:post` but was #{ @controller_http_methods.inspect }" unless @controller_http_methods.is_a?(Array) && @controller_http_methods.sort == [:get, :post].sort || @controller_http_methods == [:get] || @controller_http_methods == [:post]
        raise Error, "`include_phone_macros` must be a module, but received #{ @include_phone_macros.inspect }" unless @include_phone_macros.all? { |mod| mod.is_a?(Module) }
        nil
      end

      # Finalizes the configuration and makes it ready for use. This is called by the railtie after initialization. It
      # constantizes and performs the final steps that assumes the whole app has been initalized. Called in `to_prepare`
      # in the engine, so this is called on every code reload in development mode.
      #
      # @return [true]
      def finalize!
        return nil unless @setup
        validate!

        [
          :phone_caller_class_name,
          :phone_call_class_name,
          :response_class_name,
          :sms_conversation_class_name,
          :message_class_name,
          :recording_class_name,
        ].each do |attribute|
          value = self.send(attribute)
          raise Error, "`#{attribute}` must be set to a string name" if value.blank? || !value.is_a?(String)
          begin
            klass = value.constantize
            instance_variable_set("@#{ attribute.to_s.gsub("_name", "") }", klass)
          rescue NameError
            raise Error, "`#{attribute}` must be a valid class name but could not be found or constantized"
          end
        end

        until @include_phone_macros.empty?
          Twilio::Rails::Phone::TreeMacros.include(@include_phone_macros.pop)
        end

        Twilio::Rails::Events.clear!

        @phone_trees.finalize!
        @sms_responders.finalize!

        @finalized = true
      end

      # Base abstract registry class for configuration both phone trees and SMS responders.
      # @abstract
      class Registry
        def initialize
          @finalized = false
          @registry = {}.with_indifferent_access
          @values = []
        end

        # Finalizes the registry and makes it ready for use. It evaluates the blocks and constantizes the class names.
        # Looks up the constants each time `to_prepare` is called, so frequently in dev but only once in production.
        #
        # @return [true]
        def finalize!
          @registry = {}.with_indifferent_access
          @values.each { |value| add_to_registry(value) }
          @finalized = true
        end

        # Registers a phone tree or SMS responder. It accepts a callable, a Class, a String, or a block which returns
        # any of the aforementioned. The result will all be turned into a class when {#finalize!} is called. This can be
        # called multiple times.
        #
        # @param klass_or_proc [Class, String, Proc] value containing the Class to be lazily initialized when {#finalize!} is called.
        # @yield [nil] if a block is passed, it will be called and the result will be used as the value.
        # @yieldreturn [Class, String, Proc] containing the Class to be lazily initialized when {#finalize!} is called.
        # @return [nil]
        def register(klass_or_proc=nil, &block)
          raise Error, "Must pass either a param or a block" unless klass_or_proc.present? ^ block.present?
          value = klass_or_proc || block

          @values << value
          add_to_registry(value) if @finalized

          nil
        end

        # Returns the phone tree or SMS responder for the given name, or raises an error if it is not found.
        #
        # @param [String, Symbol] name of the phone tree or SMS responder to find.
        # @return [Class] the phone tree or SMS responder class.
        def for(name)
          @registry[name.to_s] || raise(error_class, "No responder registered for '#{ name }'")
        end

        # Returns all the phone trees or SMS responders as a read-only hash, keyed by name.
        #
        # @return [Hash] all the phone trees or SMS responders.
        def all
          @registry.dup.freeze
        end

        private

        def add_to_registry(value)
          raise NotImplementedError
        end

        def error_class
          StandardError
        end
      end

      # Registry class used to store and query SMS responders in the configuration. It is the value
      # of {Twilio::Rails::Configuration#sms_responders}.
      class SMSResponderRegistry < Registry
        private

        def add_to_registry(value)
          value = value.call if value.respond_to?(:call)
          begin
            value = value.constantize if value.is_a?(String)
          rescue NameError => e
            raise(error_class, "Responder class '#{ value }' could not be constantized")
          end
          raise(error_class, "Responder cannot be blank") unless value.present?
          raise(error_class, "Responder must be a class but got #{ value.inspect }") unless value.is_a?(Class)
          name = value.responder_name
          raise(error_class, "Responder name cannot be blank") unless name.present?
          raise(error_class, "Responder name '#{ name }' is already registered") if @registry[name]
          @registry[name] = value
        end

        def error_class
          Twilio::Rails::SMS::InvalidResponderError
        end
      end

      # Registry class used to store and query phone trees in the configuration. It is the value
      # of  {Twilio::Rails::Configuration#phone_trees}.
      class PhoneTreeRegistry < Registry
        private

        def add_to_registry(value)
          value = value.call if value.respond_to?(:call)
          begin
            value = value.constantize if value.is_a?(String)
          rescue NameError => e
            raise(error_class, "Tree class '#{ value }' could not be constantized")
          end
          raise(error_class, "Tree cannot be blank #{ value }") unless value.present?
          raise(error_class, "Tree is not a Twilio::Rails::Phone::BaseTree class #{ value }") unless value.is_a?(Class)
          raise(error_class, "Tree is not a Twilio::Rails::Phone::BaseTree #{ value }") unless value.ancestors.include?(Twilio::Rails::Phone::BaseTree)
          name = value.tree_name
          raise(error_class, "Tree name cannot be blank") unless name.present?
          raise(error_class, "Tree name '#{ name }' is already registered") if @registry[name]
          klass = klass.constantize if klass.is_a?(String)
          @registry[name] = value.tree

          value.tree.prompts.each do |prompt_handle, prompt|
            prompt.triggers.each do |trigger_name, trigger|
              Twilio::Rails::Events.register(trigger_name, *trigger.merge(tree: name, prompt: prompt_handle))
            end
          end

          @registry[name]
        end

        def error_class
          Twilio::Rails::Phone::InvalidTreeError
        end
      end
    end
  end
end
