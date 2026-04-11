defmodule JidoBuilderCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :jido_builder_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ecto_sql],
      mod: {JidoBuilderCore.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.18"},
      {:cloak_ecto, "~> 1.3"},
      {:jido, path: "../../..", override: true}
    ]
  end
end
