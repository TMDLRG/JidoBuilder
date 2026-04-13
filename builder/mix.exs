defmodule Builder.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      apps_path: "apps",
      version: @version,
      start_permanent: Mix.env() == :prod,
      name: "JidoBuilder",
      source_url: "https://github.com/TMDLRG/JidoBuilder",
      homepage_url: "https://github.com/TMDLRG/JidoBuilder",
      aliases: aliases(),
      deps: deps(),
      releases: [
        jido_builder: [
          version: "0.1.0",
          applications: [
            jido_builder_core: :permanent,
            jido_builder_runtime: :permanent,
            jido_builder_codegen: :permanent,
            jido_builder_generated: :permanent,
            jido_builder_web: :permanent
          ],
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: [
        "deps.get",
        "cmd --cd apps/jido_builder_web mix assets_setup",
        "ecto.create",
        "ecto.migrate",
        "run apps/jido_builder_core/priv/repo/seeds.exs"
      ],
      quality: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --strict",
        "dialyzer"
      ],
      q: ["quality"]
    ]
  end
end
