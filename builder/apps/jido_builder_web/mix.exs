defmodule JidoBuilderWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :jido_builder_web,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {JidoBuilderWeb.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jido_builder_core, in_umbrella: true},
      {:jido_builder_runtime, in_umbrella: true},
      {:jido_builder_codegen, in_umbrella: true},
      {:jido, path: "../../..", override: true}
    ]
  end
end
