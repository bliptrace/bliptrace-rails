# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bliptrace/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "bliptrace-rails"
  spec.version       = Bliptrace::Rails::VERSION
  spec.authors       = ["Developers Hub Sdn Bhd"]
  spec.email         = ["dev@developershub.my"]

  spec.summary       = "Ruby on Rails adapter for Bliptrace error capture and observability."
  spec.description   = "A thin Rails adapter over the runtime bliptrace Ruby gem. Adds a " \
                       "Railtie and Rack middleware that capture unhandled exceptions with " \
                       "request-context enrichment and ship them to the Bliptrace ingest API. " \
                       "Never raises into the host application."
  spec.homepage      = "https://github.com/bliptrace/bliptrace-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "bliptrace"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "railties"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", ">= 12.0"
end
