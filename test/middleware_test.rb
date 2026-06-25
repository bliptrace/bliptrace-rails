# frozen_string_literal: true

require "test_helper"

class MiddlewareTest < Minitest::Test
  def client_with(transport, config = {})
    G8Scope::Client.new(
      G8Scope::Config.new(**{ key: "k", endpoint: "http://api" }.merge(config)),
      transport
    )
  end

  def middleware(app, transport, config = {})
    G8Scope::Rails::Middleware.new(app, client: client_with(transport, config))
  end

  def test_captures_ships_valid_envelope_and_reraises
    transport = FakeTransport.new
    app = RaisingApp.new(RuntimeError.new("kaboom"))
    mw = middleware(app, transport)

    error = assert_raises(RuntimeError) { mw.call(build_rack_env) }
    assert_equal "kaboom", error.message

    assert_equal 1, transport.sent.length
    env = transport.sent.first[:envelope]

    assert_equal "ruby", env["runtime"]["name"]
    assert env["sdk"], "sdk section present"
    assert_equal "g8scope-ruby", env["sdk"]["name"]
    assert_equal "RuntimeError", env["exception"]["type"]
    assert_equal "kaboom", env["exception"]["message"]
  end

  def test_envelope_carries_request_context_without_sensitive_headers
    transport = FakeTransport.new
    mw = middleware(RaisingApp.new(RuntimeError.new("x")), transport)
    assert_raises(RuntimeError) { mw.call(build_rack_env) }

    req = transport.sent.first[:envelope]["context"]["request"]
    assert_equal "GET", req["method"]
    assert_equal "https://app.example.com/orders/42?ref=email", req["url"]
    refute req["headers"].key?("Authorization")
    refute req["headers"].key?("Cookie")
  end

  def test_never_puts_project_in_payload
    transport = FakeTransport.new
    mw = middleware(RaisingApp.new(RuntimeError.new("x")), transport)
    assert_raises(RuntimeError) { mw.call(build_rack_env) }
    refute transport.sent.first[:envelope].key?("project")
  end

  def test_passes_through_when_no_exception
    transport = FakeTransport.new
    app = ->(_env) { [200, {}, ["ok"]] }
    mw = G8Scope::Rails::Middleware.new(app, client: client_with(transport))

    status, _headers, body = mw.call(build_rack_env)
    assert_equal 200, status
    assert_equal ["ok"], body
    assert_empty transport.sent
  end

  def test_sends_nothing_when_no_key
    transport = FakeTransport.new
    mw = middleware(RaisingApp.new(RuntimeError.new("x")), transport, key: nil)
    assert_raises(RuntimeError) { mw.call(build_rack_env) }
    assert_empty transport.sent
  end

  def test_sends_nothing_when_disabled
    transport = FakeTransport.new
    mw = middleware(RaisingApp.new(RuntimeError.new("x")), transport, enabled: false)
    assert_raises(RuntimeError) { mw.call(build_rack_env) }
    assert_empty transport.sent
  end

  def test_reraises_even_if_capture_path_explodes
    # An injected client whose #capture blows up must not mask the original.
    exploding = Object.new
    def exploding.capture(*)
      raise "transport on fire"
    end

    app = RaisingApp.new(ArgumentError.new("original"))
    mw = G8Scope::Rails::Middleware.new(app, client: exploding)

    error = assert_raises(ArgumentError) { mw.call(build_rack_env) }
    assert_equal "original", error.message
  end

  def test_builds_client_from_config_when_none_injected
    # No injected client: the middleware must build one from config and not blow
    # up on construction. With no key it ships nothing but still re-raises.
    app = RaisingApp.new(RuntimeError.new("boom"))
    mw = G8Scope::Rails::Middleware.new(app)
    assert_raises(RuntimeError) { mw.call(build_rack_env) }
  end
end
