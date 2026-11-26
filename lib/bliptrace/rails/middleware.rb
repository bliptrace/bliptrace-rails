# frozen_string_literal: true

require "bliptrace"
require "bliptrace/rails/context"

module Bliptrace
  module Rails
    # Rack middleware that captures unhandled exceptions raised downstream,
    # ships them to Bliptrace enriched with request context, then RE-RAISES so
    # the host application's normal error handling is untouched.
    #
    # The capture path is fully guarded: a failure inside Bliptrace can never
    # mask or replace the original exception.
    class Middleware
      # @param app [#call] the downstream Rack app
      # @param client [Bliptrace::Client, nil] inject a client (tests); otherwise
      #   one is built from the remaining config options
      # @param config [Hash] options forwarded to Bliptrace::Config.from_hash
      def initialize(app, client: nil, **config)
        @app = app
        @client = client || build_client(config)
      end

      def call(env)
        @app.call(env)
      rescue Exception => exception # rubocop:disable Lint/RescueException
        capture(exception, env)
        raise
      end

      private

      def capture(exception, env)
        return unless @client

        @client.capture(exception, Context.build(env))
      rescue StandardError
        nil # never break the host app, never mask the original exception
      end

      def build_client(config)
        Bliptrace::Client.new(Bliptrace::Config.from_hash(config || {}))
      rescue StandardError
        nil
      end
    end
  end
end
