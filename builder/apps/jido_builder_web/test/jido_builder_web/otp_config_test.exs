defmodule JidoBuilderWeb.OtpConfigTest do
  use ExUnit.Case, async: true

  test "no bogus :jido_builder config references remain" do
    # If any file under builder/config/ still references the
    # non-existent :jido_builder OTP application, Mix emits a
    # warning on every invocation. We guard against regression
    # by grepping the compiled config for the string.
    config_dir = Path.expand("../../../../../config", __DIR__)
    files = Path.wildcard(Path.join(config_dir, "*.exs"))

    offenders =
      Enum.flat_map(files, fn file ->
        file
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _} ->
          String.contains?(line, "config :jido_builder,") or
            String.contains?(line, "config :jido_builder ")
        end)
        |> Enum.map(fn {line, n} -> "#{Path.basename(file)}:#{n}: #{String.trim(line)}" end)
      end)

    assert offenders == [], """
    Found references to the non-existent :jido_builder OTP app:

    #{Enum.join(offenders, "\n")}

    Rename to :jido_builder_runtime (or the appropriate umbrella app).
    """
  end
end
