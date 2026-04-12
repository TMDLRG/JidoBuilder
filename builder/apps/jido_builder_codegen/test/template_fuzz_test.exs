defmodule JidoBuilderCodegen.TemplateFuzzTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias JidoBuilderCodegen.Templates

  @num_runs 1_000
  @template_types [:action, :agent, :plugin, :sensor, :strategy]

  # Adversarial strings defined as module attributes to avoid sigil-delimiter
  # conflicts inside `for do` blocks and `check all` blocks.

  # A literal "#{System.cmd(...)}" as an Elixir string — #{ is escaped with \#
  @interp_system "\#{System.cmd(\"ls\", [])}"
  @interp_file "\#{File.rm_rf(\"/\")}"
  @interp_code "\#{Code.eval_string(\"System.halt()\")}"
  @interp_os "\#{:os.cmd('id')}"
  @interp_port "\#{Port.open({:spawn, \"id\"}, [])}"

  # ── Properties ─────────────────────────────────────────────────────────────

  property "adversarial descriptions never inject executable code" do
    check all type <- member_of(@template_types),
              description <- adversarial_string_gen(),
              max_runs: @num_runs do
      block = build_block(type, %{description: description})
      assert {:ok, source} = Templates.render(block)

      assert {:ok, ast} = Code.string_to_quoted(source),
             "Template #{type}: non-parseable source with description=#{inspect(description)}\n\nSource:\n#{String.slice(source, 0, 300)}"

      refute contains_dangerous_call?(ast),
             "Template #{type}: dangerous remote call in AST with description=#{inspect(description)}"
    end
  end

  property "module names not matching the safe pattern are rejected" do
    check all type <- member_of(@template_types),
              mod <- module_name_gen(),
              max_runs: @num_runs do
      block = build_block(type, %{module: mod})
      result = Templates.render(block)

      if valid_module_name?(mod) do
        assert {:ok, source} = result,
               "#{type}: valid module #{inspect(mod)} unexpectedly rejected"

        assert {:ok, ast} = Code.string_to_quoted(source),
               "#{type}: valid module #{inspect(mod)} rendered non-parseable source"

        refute contains_dangerous_call?(ast),
               "#{type}: dangerous call found with valid module #{inspect(mod)}"
      else
        assert {:error, :invalid_module_name} = result,
               "#{type}: expected rejection for invalid module #{inspect(mod)}, got #{inspect(result)}"
      end
    end
  end

  # ── Hand-crafted edge cases ────────────────────────────────────────────────

  test "triple-quote heredoc injection in description is neutralised in all templates" do
    payload = ~s(evil """ close heredoc)

    for type <- @template_types do
      block = build_block(type, %{description: payload})
      assert {:ok, source} = Templates.render(block), "#{type}: render failed"

      assert {:ok, _ast} = Code.string_to_quoted(source),
             "#{type}: source failed to parse after triple-quote in description:\n#{source}"
    end
  end

  test "EEx-style interpolation in description becomes an inert string literal" do
    for type <- @template_types do
      block = build_block(type, %{description: @interp_system})
      assert {:ok, source} = Templates.render(block)

      assert {:ok, ast} = Code.string_to_quoted(source),
             "#{type}: interpolation string not neutralised"

      refute contains_dangerous_call?(ast),
             "#{type}: System.cmd appeared as a live call in AST"
    end
  end

  test "File / Code / :os / Port interpolation patterns are neutralised" do
    payloads = [@interp_file, @interp_code, @interp_os, @interp_port]

    for type <- @template_types, description <- payloads do
      block = build_block(type, %{description: description})
      assert {:ok, source} = Templates.render(block)
      assert {:ok, ast} = Code.string_to_quoted(source)
      refute contains_dangerous_call?(ast), "#{type}: dangerous call for #{inspect(description)}"
    end
  end

  test "newline injection in module name is rejected in all templates" do
    payload = "Foo\nSystem.cmd(\"rm\", [\"-rf\", \"/\"])\ndefmodule Bar"

    for type <- @template_types do
      assert {:error, :invalid_module_name} = Templates.render(build_block(type, %{module: payload})),
             "#{type}: newline injection not rejected"
    end
  end

  test "empty module name is rejected in all templates" do
    for type <- @template_types do
      assert {:error, :invalid_module_name} =
               Templates.render(build_block(type, %{module: ""})),
             "#{type}: empty module name not rejected"
    end
  end

  test "lowercase-start module name is rejected in all templates" do
    for type <- @template_types do
      assert {:error, :invalid_module_name} =
               Templates.render(build_block(type, %{module: "badModule"})),
             "#{type}: lowercase module name not rejected"
    end
  end

  # ── Helpers ────────────────────────────────────────────────────────────────

  defp build_block(:action, overrides) do
    Map.merge(
      %{type: :action, module: "Fuzz.Safe", name: "safe_action", description: "safe"},
      overrides
    )
  end

  defp build_block(type, overrides) do
    Map.merge(%{type: type, module: "Fuzz.Safe", description: "safe"}, overrides)
  end

  defp contains_dangerous_call?(ast) do
    {_, found} =
      Macro.prewalk(ast, false, fn
        {{:., _, [{:__aliases__, _, [top | _]}, _]}, _, _} = node, _acc
        when top in [:System, :File, :Code, :Port] ->
          {node, true}

        {{:., _, [mod, _]}, _, _} = node, _acc
        when is_atom(mod) and mod in [:os, :erlang] ->
          {node, true}

        node, acc ->
          {node, acc}
      end)

    found
  end

  defp valid_module_name?(mod) when is_binary(mod) do
    Regex.match?(~r/^[A-Z][A-Za-z0-9_]*(\.[A-Z][A-Za-z0-9_]*)*$/, mod)
  end

  defp valid_module_name?(_), do: false

  # ── Generators ─────────────────────────────────────────────────────────────

  defp adversarial_string_gen do
    one_of([
      # Heredoc-closing sequences (break raw """...""" interpolation)
      constant(~s(""")),
      constant("evil\n\"\"\""),
      constant("\"\"\"\nSystem.cmd(\"ls\", [])"),
      constant("  \"\"\"\n  evil"),
      # Elixir interpolation patterns (using escaped #{ to avoid compile-time eval)
      constant("\#{System.cmd(\"ls\", [])}"),
      constant("\#{File.rm_rf(\"/\")}"),
      constant("\#{Code.eval_string(\"System.halt()\")}"),
      constant("\#{:os.cmd('id')}"),
      constant("\#{Port.open({:spawn, \"id\"}, [])}"),
      # Code fragments after heredoc close
      constant("end\nSystem.cmd(\"ls\", [])"),
      constant("\"\"\"\nend\nIO.puts(System.cmd(\"id\", []))"),
      # Unicode specials
      constant("\u202e evil reverse override"),
      constant("\u0000 null byte"),
      # Shell metacharacters (safe in Elixir strings)
      constant("; rm -rf /; echo"),
      constant("`id`"),
      # Random printable (broad coverage)
      string(:printable, min_length: 0, max_length: 500)
    ])
  end

  defp module_name_gen do
    one_of([
      # Newline injection
      gen all suffix <- string(:alphanumeric, min_length: 1, max_length: 15) do
        "Foo\n" <> suffix
      end,
      constant("Foo; System.cmd(\"ls\", [])"),
      constant("Foo do\n:malicious\nend\ndefmodule Bar"),
      constant(""),
      constant(".Foo"),
      constant("Foo."),
      constant("Foo..Bar"),
      constant("Foo Bar"),
      # Lowercase start
      gen all s <- string(:alphanumeric, min_length: 1, max_length: 15) do
        String.downcase(s)
      end,
      # Valid module names — must produce safe output
      constant("Fuzz.Safe"),
      constant("Generated.MyModule"),
      constant("A"),
      constant("Foo.Bar.Baz"),
      # Random strings
      string(:printable, min_length: 0, max_length: 50)
    ])
  end
end
