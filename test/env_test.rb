# frozen_string_literal: true

require "test_helper"
require "bliptrace/rails" # Railtie self-guards outside Rails

class EnvTest < Minitest::Test
  def with_env(vars)
    saved = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    saved.each { |k, v| ENV[k] = v }
  end

  def test_bliptrace_wins_over_legacy_env
    with_env("BLIPTRACE_KEY" => "new", "G8SCOPE_KEY" => "old") do
      assert_equal "new", Bliptrace::Rails.env("KEY")
    end
  end

  def test_falls_back_to_legacy_env_when_bliptrace_unset
    with_env("BLIPTRACE_KEY" => nil, "G8SCOPE_KEY" => "old") do
      assert_equal "old", Bliptrace::Rails.env("KEY")
    end
  end

  def test_nil_when_neither_set
    with_env("BLIPTRACE_KEY" => nil, "G8SCOPE_KEY" => nil) do
      assert_nil Bliptrace::Rails.env("KEY")
    end
  end
end
