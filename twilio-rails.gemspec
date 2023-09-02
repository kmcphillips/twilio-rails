require_relative "lib/twilio/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "twilio-rails"
  spec.version     = Twilio::Rails::VERSION
  spec.licenses    = ["MIT"]
  spec.authors     = ["Kevin McPhillips"]
  spec.email       = ["github@kevinmcphillips.ca"]
  spec.homepage    = "https://github.com/kmcphillips/twilio-rails"
  spec.summary     = "A framework for building rich phone interactions in Rails using Twilio."
  spec.description = "A Rails engine that provides the framework to build complex phone interactions using the Twilio API."

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kmcphillips/twilio-rails"
  spec.metadata["changelog_uri"] = "https://github.com/kmcphillips/twilio-rails/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/twilio-rails"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "twilio-ruby", ">= 5.0"
  spec.add_dependency "active_operation", ">= 1.0"
  spec.add_dependency "faraday"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"
end
