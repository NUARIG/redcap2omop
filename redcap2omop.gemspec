# Maintain your gem's version:
require_relative "lib/redcap2omop/version"

Gem::Specification.new do |spec|
  spec.name        = "redcap2omop"
  spec.version     = Redcap2omop::VERSION
  spec.authors     = ["Michael Gurley", "Yulia Bushmanova"]
  spec.email       = ["y-bushmanova@northwestern.edu"]
  spec.homepage    = "https://github.com/NUARIG/redcap2omop"
  spec.summary     = "Summary of Redcap2omop."
  spec.description = "Description of Redcap2omop."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://github.com/NUARIG/redcap2omop"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/NUARIG/redcap2omop"
  spec.metadata["changelog_uri"] = "https://github.com/NUARIG/redcap2omop"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.test_files = Dir['spec/**/*']

  spec.add_dependency "rails", "~> 6.1.1"
  spec.add_dependency 'sass-rails', '>= 6'
  spec.add_dependency 'highline', '~> 2.0.3'
  spec.add_dependency 'rest-client', '~> 2.1.0'
  spec.add_dependency 'american_date', '~> 1.1.1'

  spec.add_development_dependency 'pg', '~> 1.2.3'
  spec.add_development_dependency 'rspec-rails', '~> 5.0.0'
  spec.add_development_dependency 'factory_bot_rails', '~> 6.1.0'
  spec.add_development_dependency 'faker', '~> 2.17.0'
  spec.add_development_dependency 'shoulda-matchers', '~> 4.5.1'
  spec.add_development_dependency 'webmock', '~> 3.12.1'
end
