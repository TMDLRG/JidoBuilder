import Config

# This file is read EVERY time the release boots (unlike compile-
# time config.exs). It is the ONLY place prod secrets live.
# Dev and test do not read this file.

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      Example: DATABASE_PATH=/var/lib/jido_builder/jido_builder.db
      """

  config :jido_builder_core, JidoBuilderCore.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :jido_builder_web, JidoBuilderWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  cloak_key =
    System.get_env("JIDO_BUILDER_CLOAK_KEY") ||
      raise """
      environment variable JIDO_BUILDER_CLOAK_KEY is missing.
      This is a base64-encoded 32-byte key used by Cloak to encrypt
      secrets at rest. Generate with:
        mix run -e 'IO.puts(Base.encode64(:crypto.strong_rand_bytes(32)))'
      """

  config :jido_builder_core, JidoBuilderCore.Vault,
    ciphers: [
      default: {
        Cloak.Ciphers.AES.GCM,
        tag: "AES.GCM.V1",
        key: Base.decode64!(cloak_key)
      }
    ]
end
