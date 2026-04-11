import Config

config :jido_builder_core,
  ecto_repos: [JidoBuilderCore.Repo],
  generators: [timestamp_type: :utc_datetime_usec]

config :jido_builder_core, JidoBuilderCore.Repo,
  migration_primary_key: [type: :id],
  migration_timestamps: [type: :utc_datetime_usec]

config :jido_builder_core, JidoBuilderCore.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1",
      key:
        Base.decode64!(
          System.get_env("JIDO_BUILDER_CLOAK_KEY") ||
            "MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA="
        )
    }
  ]

config :jido_builder_web,
  ecto_repos: [JidoBuilderCore.Repo],
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

config :jido_builder, JidoBuilderRuntime.Jido,
  max_tasks: 1000,
  agent_pools: [],
  storage: {Jido.Storage.ETS, [table: :jido_builder_storage]}

config :jido_builder,
  features: [
    redis_enabled: System.get_env("JIDO_BUILDER_REDIS_ENABLED", "false") == "true",
    llm_enabled: System.get_env("JIDO_BUILDER_LLM_ENABLED", "false") == "true"
  ],
  integrations: [
    redis_url: System.get_env("JIDO_BUILDER_REDIS_URL", "redis://127.0.0.1:6379/0"),
    llm_provider: System.get_env("JIDO_BUILDER_LLM_PROVIDER", "none"),
    llm_api_base: System.get_env("JIDO_BUILDER_LLM_API_BASE", "")
  ]

import_config "#{config_env()}.exs"
