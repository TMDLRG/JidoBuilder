import Config

config :jido_builder_web,
  ecto_repos: [],
  generators: [timestamp_type: :utc_datetime]

config :jido_builder_web, JidoBuilderWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: JidoBuilderWeb.ErrorHTML, json: JidoBuilderWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: JidoBuilder.PubSub,
  live_view: [signing_salt: "change-me"]

config :esbuild,
  version: "0.25.0",
  jido_builder_web: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets),
    cd: Path.expand("../apps/jido_builder_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "4.1.4",
  jido_builder_web: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/app.css),
    cd: Path.expand("../apps/jido_builder_web", __DIR__)
  ]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
