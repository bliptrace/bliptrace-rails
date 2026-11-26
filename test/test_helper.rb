# frozen_string_literal: true

# minitest ships with Ruby but is not always on the default load path (e.g. the
# macOS system Ruby installs it under /Library/Ruby/Gems). Discover it so the
# suite runs standalone with:
#   ruby -I../bliptrace-ruby/lib -Ilib -Itest test/middleware_test.rb
begin
  require "minitest/autorun"
rescue LoadError
  Gem.path.dup.push("/Library/Ruby/Gems/#{RUBY_VERSION[/\d+\.\d+/]}.0").each do |base|
    candidate = Dir["#{base}/gems/minitest-*/lib"].sort.last
    $LOAD_PATH.unshift(candidate) if candidate && Dir.exist?(candidate)
  end
  require "minitest/autorun"
end

# Framework-light: load only the runtime gem + the adapter's testable pieces.
# We do NOT require "bliptrace/rails" because that pulls in the Railtie (guarded,
# but unnecessary here) — we load exactly what we test.
require "bliptrace"
require "bliptrace/rails/version"
require "bliptrace/rails/context"
require "bliptrace/rails/middleware"

# A fake transport that records every envelope instead of making a network call.
class FakeTransport
  attr_reader :sent

  def initialize
    @sent = []
  end

  def send_envelope(endpoint, key, envelope, timeout = 3)
    @sent << { endpoint: endpoint, key: key, envelope: envelope, timeout: timeout }
    nil
  end
end

# A minimal Rack app that always raises the given exception.
class RaisingApp
  def initialize(exception)
    @exception = exception
  end

  def call(_env)
    raise @exception
  end
end

# A trivial Rack env builder for tests — no Rack required.
def build_rack_env(overrides = {})
  {
    "REQUEST_METHOD" => "GET",
    "rack.url_scheme" => "https",
    "HTTP_HOST" => "app.example.com",
    "SERVER_NAME" => "app.example.com",
    "SERVER_PORT" => "443",
    "PATH_INFO" => "/orders/42",
    "QUERY_STRING" => "ref=email",
    "HTTP_USER_AGENT" => "RSpec",
    "HTTP_AUTHORIZATION" => "Bearer secret-token",
    "HTTP_COOKIE" => "session=abc123"
  }.merge(overrides)
end
