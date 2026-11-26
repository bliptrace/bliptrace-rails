# frozen_string_literal: true

require "test_helper"

class ContextTest < Minitest::Test
  def test_builds_request_method_and_url
    ctx = Bliptrace::Rails::Context.build(build_rack_env)
    req = ctx["request"]

    assert_equal "GET", req["method"]
    assert_equal "https://app.example.com/orders/42?ref=email", req["url"]
  end

  def test_strips_authorization_and_cookie_headers
    ctx = Bliptrace::Rails::Context.build(build_rack_env)
    headers = ctx["request"]["headers"]

    refute headers.key?("Authorization"), "Authorization must be stripped"
    refute headers.key?("Cookie"), "Cookie must be stripped"
    assert_equal "RSpec", headers["User-Agent"]
  end

  def test_custom_section_is_an_empty_hash
    ctx = Bliptrace::Rails::Context.build(build_rack_env)
    assert_equal({}, ctx["custom"])
  end

  def test_omits_default_port_from_url
    env = build_rack_env(
      "rack.url_scheme" => "http", "HTTP_HOST" => nil,
      "SERVER_NAME" => "host", "SERVER_PORT" => "80"
    )
    assert_equal "http://host/orders/42?ref=email", Bliptrace::Rails::Context.build(env)["request"]["url"]
  end

  def test_handles_nil_env_without_raising
    ctx = Bliptrace::Rails::Context.build(nil)
    assert_nil ctx["request"]["method"]
    assert_nil ctx["request"]["url"]
    assert_equal({}, ctx["request"]["headers"])
    assert_equal({}, ctx["custom"])
  end
end
