# frozen_string_literal: true

module G8Scope
  module Rails
    # Builds envelope context from a Rack `env` hash. Pure and duck-typed so it
    # is unit-testable without Rack or Rails loaded. Sensitive request headers
    # (authorization, cookie) are stripped before anything leaves the process.
    #
    # NOTE: `project` is never placed in the payload — it is resolved server-side
    # from the ingest key.
    module Context
      module_function

      # Header names (lower-case, dash form) that must never be shipped.
      SENSITIVE_HEADERS = %w[authorization cookie].freeze

      # @param env [Hash] a Rack environment hash
      # @return [Hash] envelope context with "request" and "custom" sections
      def build(env)
        env ||= {}

        {
          "request" => {
            "method" => env["REQUEST_METHOD"],
            "url" => url_for(env),
            "headers" => headers_for(env)
          },
          "custom" => {}
        }
      rescue StandardError
        { "request" => {}, "custom" => {} }
      end

      # Reconstruct the request URL from Rack env keys.
      def url_for(env)
        scheme = env["rack.url_scheme"] || "http"
        host = env["HTTP_HOST"] || env["SERVER_NAME"]
        return nil if host.nil? || host.to_s.empty?

        port = env["SERVER_PORT"].to_s
        default_port = scheme == "https" ? "443" : "80"
        host_with_port =
          if env["HTTP_HOST"] || port.empty? || port == default_port
            host
          else
            "#{host}:#{port}"
          end

        path = env["PATH_INFO"].to_s
        path = "/" if path.empty?
        query = env["QUERY_STRING"].to_s

        url = "#{scheme}://#{host_with_port}#{path}"
        url += "?#{query}" unless query.empty?
        url
      end

      # Extract HTTP_* headers, normalise names, strip sensitive ones.
      def headers_for(env)
        headers = {}
        env.each do |key, value|
          next unless key.is_a?(String) && key.start_with?("HTTP_")

          name = header_name(key)
          next if SENSITIVE_HEADERS.include?(name.downcase)

          headers[name] = value.to_s
        end
        headers
      end

      # Convert "HTTP_CONTENT_TYPE" -> "Content-Type".
      def header_name(key)
        key.sub(/\AHTTP_/, "").split("_").map { |p| p.capitalize }.join("-")
      end
    end
  end
end
