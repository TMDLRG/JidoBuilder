defmodule JidoBuilderCore.Repo do
  use Ecto.Repo,
    otp_app: :jido_builder_core,
    adapter: Ecto.Adapters.SQLite3
end
