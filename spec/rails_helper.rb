require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

require "sqlite3"
require "webmock/rspec"
require "timecop"
require "factory_bot_rails"

Dir[Rails.root.join(File.expand_path("../spec/support", __dir__), "**", "*.rb")].sort.each { |f| require f }

# Load the schema for the dummy app if it changes, otherwise commit the db file.
# load "dummy/db/schema.rb"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  if Gem.loaded_specs["rails"].version < Gem::Version.create("7.1")
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
  else
    config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
  end
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper
end
