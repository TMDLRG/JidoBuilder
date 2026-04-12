import Config

config :jido_builder_core, JidoBuilderCore.Repo,
  database:
    System.get_env("JIDO_BUILDER_SQLITE_PATH") || "/var/lib/jido_builder/jido_builder_prod.db",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :jido_builder_web, JidoBuilderWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info

# 7.11 — Structured JSON logging in prod.
# Uses the built-in Erlang :logger JSON formatter (OTP 27+).
config :logger, :default_handler,
  formatter:
    {:logger_formatter,
     %{
       template: [:msg],
       single_line: true
     }}

config :jido_builder_core, JidoBuilderCore.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1",
      key:
        Base.decode64!(
          System.get_env("JIDO_BUILDER_CLOAK_KEY") || raise("JIDO_BUILDER_CLOAK_KEY is missing")
        )
    }
  ]
