import Config

config :jido_builder_web, JidoBuilderWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-change-me",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
