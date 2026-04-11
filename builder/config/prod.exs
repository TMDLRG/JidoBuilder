import Config

config :jido_builder_core, JidoBuilderCore.Repo,
  database:
    System.get_env("JIDO_BUILDER_SQLITE_PATH") || "/var/lib/jido_builder/jido_builder_prod.db",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :jido_builder_web, JidoBuilderWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info

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
