import Config

config :jido_builder_core, JidoBuilderCore.Repo,
  database: Path.expand("../jido_builder_test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :jido_builder_web, JidoBuilderWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-change-me",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :jido_builder_core, JidoBuilderCore.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1",
      key:
        Base.decode64!(
          System.get_env("JIDO_BUILDER_CLOAK_KEY_TEST") ||
            "ZmVkY2JhOTg3NjU0MzIxMGZlZGNiYTk4NzY1NDMyMTA="
        )
    }
  ]
