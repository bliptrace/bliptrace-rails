# frozen_string_literal: true

# This file references Rails constants and is only meaningful inside a Rails
# application. It is guarded so it can be required safely even when Rails is not
# loaded (e.g. during this adapter's framework-light test suite).
if defined?(Rails::Railtie)
  require "g8scope/rails/middleware"

  module G8Scope
    module Rails
      # Wires the g8scope capture middleware into the host Rails app's stack and
      # sources its configuration from `Rails.application.config.g8scope` and/or
      # ENV. Configuration precedence: explicit config wins over ENV.
      class Railtie < ::Rails::Railtie
        config.g8scope = {} unless config.respond_to?(:g8scope) && config.g8scope

        initializer "g8scope.middleware" do |app|
          options = G8Scope::Rails::Railtie.resolve_config(app)
          app.middleware.use(G8Scope::Rails::Middleware, **options)
        end

        # Merge app config over ENV defaults. `project` is intentionally absent:
        # it is resolved server-side from the ingest key.
        def self.resolve_config(app)
          env_config = {
            key: ENV["G8SCOPE_KEY"],
            endpoint: ENV["G8SCOPE_ENDPOINT"],
            environment: ENV["G8SCOPE_ENVIRONMENT"] || (defined?(::Rails) ? ::Rails.env.to_s : nil),
            release: ENV["G8SCOPE_RELEASE"]
          }.reject { |_, v| v.nil? }

          app_config = app.config.respond_to?(:g8scope) ? (app.config.g8scope || {}) : {}
          symbolised = {}
          app_config.each { |k, v| symbolised[k.to_sym] = v }

          env_config.merge(symbolised)
        end
      end
    end
  end
end
