# frozen_string_literal: true

require "g8scope"
require "g8scope/rails/version"
require "g8scope/rails/context"
require "g8scope/rails/middleware"

# Rails framework adapter for g8scope.
#
# A thin layer over the runtime `g8scope` Ruby gem: it adds a Rack middleware
# that captures unhandled exceptions with request-context enrichment, plus a
# Railtie that auto-inserts the middleware into a Rails app's middleware stack.
# It must NEVER break the host application.
module G8Scope
  module Rails
    # Reads BLIPTRACE_<name> from ENV, falling back to the deprecated
    # G8SCOPE_<name> (removed in the next major) when unset.
    def self.env(name)
      ENV["BLIPTRACE_#{name}"] || ENV["G8SCOPE_#{name}"]
    end
  end
end

# The Railtie references Rails constants; it self-guards with `defined?` so this
# require is a no-op outside a Rails application (and during the test suite).
require "g8scope/rails/railtie"
