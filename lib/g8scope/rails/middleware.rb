# frozen_string_literal: true

require "g8scope"
require "g8scope/rails/context"

module G8Scope
  module Rails
    # Rack middleware that captures unhandled exceptions raised downstream,
    # ships them to g8scope enriched with request context, then RE-RAISES so
    # the host application's normal error handling is untouched.
    #
    # The capture path is fully guarded: a failure inside g8scope can never
    # mask or replace the original exception.
    class Middleware
      # @param app [#call] the downstream Rack app
      # @param client [G8Scope::Client, nil] inject a client (tests); otherwise
      #   one is built from the remaining config options
      # @param config [Hash] options forwarded to G8Scope::Config.from_hash
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
        G8Scope::Client.new(G8Scope::Config.from_hash(config || {}))
      rescue StandardError
        nil
      end
    end
  end
end
