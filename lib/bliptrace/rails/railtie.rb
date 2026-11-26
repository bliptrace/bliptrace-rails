# frozen_string_literal: true

# This file references Rails constants and is only meaningful inside a Rails
# application. It is guarded so it can be required safely even when Rails is not
# loaded (e.g. during this adapter's framework-light test suite).
if defined?(Rails::Railtie)
  require "bliptrace/rails/middleware"

  module Bliptrace
    module Rails
      # Wires the Bliptrace capture middleware into the host Rails app's stack and
      # sources its configuration from `Rails.application.config.bliptrace`
      # and/or ENV. Configuration precedence: explicit config wins over ENV.
      class Railtie < ::Rails::Railtie
        config.bliptrace = {} unless config.respond_to?(:bliptrace) && config.bliptrace

        initializer "bliptrace.middleware" do |app|
          options = Bliptrace::Rails::Railtie.resolve_config(app)
          app.middleware.use(Bliptrace::Rails::Middleware, **options)
        end

        # Merge app config over ENV defaults. `project` is intentionally absent:
        # it is resolved server-side from the ingest key.
        def self.resolve_config(app)
          env_config = {
            key: Bliptrace::Rails.env("KEY"),
            endpoint: Bliptrace::Rails.env("ENDPOINT"),
            environment: Bliptrace::Rails.env("ENVIRONMENT") || (defined?(::Rails) ? ::Rails.env.to_s : nil),
            release: Bliptrace::Rails.env("RELEASE")
          }.reject { |_, v| v.nil? }

          symbolised = {}
          app_config = app.config.respond_to?(:bliptrace) ? (app.config.bliptrace || {}) : {}
          app_config.each { |k, v| symbolised[k.to_sym] = v }

          env_config.merge(symbolised)
        end
      end
    end
  end
end
