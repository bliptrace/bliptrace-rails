# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "g8scope/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "g8scope-rails"
  spec.version       = G8Scope::Rails::VERSION
  spec.authors       = ["Developers Hub Sdn Bhd"]
  spec.email         = ["dev@developershub.my"]

  spec.summary       = "Ruby on Rails adapter for g8scope error capture and observability."
  spec.description   = "A thin Rails adapter over the runtime g8scope Ruby gem. Adds a " \
                       "Railtie and Rack middleware that capture unhandled exceptions with " \
                       "request-context enrichment and ship them to the g8scope ingest API. " \
                       "Never raises into the host application."
  spec.homepage      = "https://github.com/developers-hub-my/g8scope-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "g8scope"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "railties"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", ">= 12.0"
end
