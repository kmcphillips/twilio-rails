# frozen_string_literal: true
class Twilio::Rails::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  include Rails::Generators::Migration

  class << self
    def next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      ActiveRecord::Migration.next_migration_number(next_migration_number)
    end
  end

  def setup_initializer
    copy_file "initializer.rb", "config/initializers/twilio_rails.rb"
  end

  def setup_routes
    route "mount Twilio::Rails::Engine => '/twilio'"
  end

  def setup_migrations
    migration_template "migration.rb", "db/migrate/install_twilio_rails.rb"
  end

  def setup_models
    copy_file "message.rb", "app/models/message.rb"
    copy_file "phone_caller.rb", "app/models/phone_caller.rb"
    copy_file "phone_call.rb", "app/models/phone_call.rb"
    copy_file "recording.rb", "app/models/recording.rb"
    copy_file "response.rb", "app/models/response.rb"
    copy_file "sms_conversation.rb", "app/models/sms_conversation.rb"
  end
end
