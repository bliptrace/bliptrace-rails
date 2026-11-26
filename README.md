# bliptrace-rails

The **Ruby on Rails** adapter for [Bliptrace](https://github.com/bliptrace/bliptrace-ruby) — a central, multi-tenant, runtime-agnostic error-capture and observability platform.

This is a **thin** adapter over the runtime `bliptrace` Ruby gem. It adds:

- a **Rack middleware** that captures unhandled exceptions raised in your app, enriches them with request context, ships them to the Bliptrace ingest API, and then **re-raises** so Rails' normal error handling continues untouched;
- a **Railtie** that auto-inserts the middleware into your application's middleware stack and reads configuration from your Rails config or the environment.

It will **never break your application**: every step of the capture path is guarded, so a failure inside Bliptrace can neither slow nor mask your own error handling.

## Installation

Add it to your `Gemfile`:

```ruby
gem "bliptrace-rails"
```

Then:

```bash
bundle install
```

The Railtie inserts the middleware automatically — no initialiser is required.

## Configuration

Configure via your Rails application config:

```ruby
# config/application.rb (or an environment file)
config.bliptrace = {
  key: "your-ingest-key",
  # endpoint:    "https://ingest.bliptrace.com", # optional override
  # environment: "production",                        # defaults to Rails.env
  # release:     "1.4.2"
}
```

…or entirely through the environment:

| Variable               | Purpose                                  |
| ---------------------- | ---------------------------------------- |
| `BLIPTRACE_KEY`        | Ingest key (required to enable capture)  |
| `BLIPTRACE_ENDPOINT`   | Ingest endpoint override                 |
| `BLIPTRACE_ENVIRONMENT` | Environment label (defaults to `Rails.env`) |
| `BLIPTRACE_RELEASE`    | Release / version identifier             |

Explicit `config.bliptrace` values take precedence over environment variables.

> **Deprecated:** the old `G8SCOPE_*` variables are still
> read as a fallback when the `BLIPTRACE` name is unset. They will be removed in
> the next major version.

With **no key configured the adapter captures nothing** — it stays completely dormant.

> **Project resolution.** Your `project` is never sent in the payload. The Bliptrace server resolves the project **server-side from the ingest key**, which prevents spoofing. You only supply the key.

## Privacy

Sensitive request headers — `Authorization` and `Cookie` — are stripped from the captured context before anything leaves your process. Further PII scrubbing is configurable through the underlying `bliptrace` gem via `scrub_keys`.

## Manual usage

If you prefer to wire the middleware yourself (e.g. in a non-Rails Rack app), you can insert it directly:

```ruby
require "bliptrace/rails/middleware"

use Bliptrace::Rails::Middleware, key: ENV["BLIPTRACE_KEY"]
```

## Development

The adapter is framework-light by design: its middleware, context builder, and config glue depend only on the `bliptrace` gem plus the standard library. Run the test suite against the sibling runtime gem without bundler or an installed Rails:

```bash
ruby -I../bliptrace-ruby/lib -Ilib -Itest test/middleware_test.rb
```

or simply:

```bash
rake test
```

## Licence

MIT. See [LICENSE](LICENSE).
