defmodule JidoBuilderCodegen.FileWriterFuzzTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias JidoBuilderCodegen.FileWriter

  @num_runs 1_000

  setup do
    root = Path.join(System.tmp_dir!(), "jido_fuzz_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    Application.put_env(:jido_builder_codegen, :generated_lib_dir, root)
    # Normalise root once — FileWriter does Path.expand internally, so both
    # sides of every comparison must use the same normalised form.
    expanded_root = Path.expand(root)

    on_exit(fn ->
      Application.delete_env(:jido_builder_codegen, :generated_lib_dir)
      File.rm_rf!(root)
    end)

    {:ok, root: expanded_root}
  end

  # ── Hand-crafted edge cases ────────────────────────────────────────────────

  test "null-byte embedded in segment does NOT create a new escape vector", %{root: root} do
    # Path.expand treats "\x00.." as a literal dir name (not "..").
    # The following ".." only climbs back out of that dir, landing inside root.
    # The final resolved path contains no null byte and is inside root.
    assert {:ok, %{path: written_path}} = FileWriter.write("valid/\x00../../etc/secret", "bad")
    assert String.starts_with?(written_path, root),
           "Expected path to be inside root, got #{inspect(written_path)}"
  end

  test "URL-encoded dot-dot is treated as a literal filename (not an escape)", %{root: root} do
    # %2e%2e is NOT decoded by Path.expand — it becomes a directory named
    # literally "%2e%2e" inside root, not a ".." traversal.
    assert {:ok, %{path: written_path}} = FileWriter.write("%2e%2e/safe.ex", "ok")
    assert String.starts_with?(written_path, root),
           "Expected URL-encoded path to be inside root, got #{inspect(written_path)}"
  end

  test "Windows-style backslash escape is blocked", %{root: _root} do
    # On Windows, Path.expand recognises \\ as a separator, so "..\\x" is
    # equivalent to "../x" and must be rejected.
    assert {:error, :path_outside_generated_lib} =
             FileWriter.write("..\\escape.ex", "bad")
  end

  test "paths with only dot-dot are rejected", %{root: _root} do
    assert {:error, :path_outside_generated_lib} = FileWriter.write("../", "bad")
    assert {:error, :path_outside_generated_lib} = FileWriter.write("../../", "bad")
  end

  test "absolute Unix path is rejected", %{root: _root} do
    assert {:error, :path_outside_generated_lib} =
             FileWriter.write("/etc/passwd", "bad")
  end

  # ── StreamData property: adversarial paths must always be rejected ─────────

  property "escape sequences are always rejected", %{root: _root} do
    check all path <- escape_path_gen(), max_runs: @num_runs do
      result = FileWriter.write(path, "content")

      assert result == {:error, :path_outside_generated_lib},
             "Expected sandbox to block #{inspect(path)}, got #{inspect(result)}"
    end
  end

  # ── StreamData property: safe relative paths are always accepted ───────────

  property "paths composed of safe segments are always accepted", %{root: root} do
    check all path <- safe_path_gen(), max_runs: @num_runs do
      assert {:ok, %{path: written_path}} = FileWriter.write(path, "x"),
             "Expected sandbox to accept #{inspect(path)}"

      assert String.starts_with?(written_path, root),
             "Expected written path #{inspect(written_path)} inside root #{inspect(root)}"
    end
  end

  # ── Generators ─────────────────────────────────────────────────────────────

  # Generates paths that MUST escape the sandbox root.
  defp escape_path_gen do
    one_of([
      # N pure leading dot-dot escapes
      gen all depth <- integer(1..8),
              suffix <- alphanumeric_segment() do
        String.duplicate("../", depth) <> suffix
      end,

      # Descend into subdirs then escape by a greater depth
      gen all descent <- integer(1..4),
              extra <- integer(1..4),
              suffix <- alphanumeric_segment() do
        subdirs = Enum.map_join(1..descent, "/", fn i -> "d#{i}" end)
        escapes = String.duplicate("../", descent + extra)
        subdirs <> "/" <> escapes <> suffix
      end,

      # Absolute Unix paths (cannot be inside any relative root)
      gen all segment <- alphanumeric_segment() do
        "/etc/" <> segment
      end,

      # Windows-style dot-dot with backslash separator
      gen all depth <- integer(1..4),
              suffix <- alphanumeric_segment() do
        String.duplicate("..\\", depth) <> suffix
      end
    ])
  end

  # Generates paths that MUST resolve inside the sandbox root:
  # only lowercase alphanumeric segments joined by "/", no leading slash, no "..".
  defp safe_path_gen do
    gen all segments <- list_of(alphanumeric_segment(), min_length: 1, max_length: 6),
            filename <- alphanumeric_segment() do
      Path.join(segments ++ [filename <> ".ex"])
    end
  end

  defp alphanumeric_segment do
    gen all chars <-
              list_of(
                member_of(Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9)),
                min_length: 1,
                max_length: 12
              ) do
      List.to_string(chars)
    end
  end
end
