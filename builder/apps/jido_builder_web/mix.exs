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
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {JidoBuilderWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:jido_builder_core, in_umbrella: true},
      {:jido_builder_runtime, in_umbrella: true},
      {:jido_builder_codegen, in_umbrella: true},
      {:jido, path: "../../..", override: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      assets_setup: ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      assets_build: ["tailwind jido_builder_web", "esbuild jido_builder_web"],
      assets_deploy: [
        "tailwind jido_builder_web --minify",
        "esbuild jido_builder_web --minify",
        "phx.digest"
      ]
    ]
  end
end
