defmodule JidoBuilderCodegenTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCodegen.{CompileQueue, FileWriter, Templates}

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "jido_codegen_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    Application.put_env(:jido_builder_codegen, :generated_lib_dir, tmp_dir)

    on_exit(fn ->
      Application.delete_env(:jido_builder_codegen, :generated_lib_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, queue} = start_supervised(CompileQueue)
    {:ok, queue: queue, tmp_dir: tmp_dir}
  end

  test "template render for action emits module source" do
    block = %{type: :action, module: "Generated.ActionOne", name: "a1", description: "generated"}

    assert {:ok, source} = Templates.render(block)
    assert source =~ "defmodule Generated.ActionOne"
    assert source =~ "use Jido.Action"
  end

  test "template render escapes triple-quote injection in description" do
    block = %{
      type: :action,
      module: "Generated.ActionInjection",
      name: "injected",
      description: ~s(evil """ injection)
    }

    assert {:ok, source} = Templates.render(block)

    refute String.contains?(source, ~s(@moduledoc """))

    tmp_path =
      Path.join(System.tmp_dir!(), "gen_#{System.unique_integer([:positive])}.ex")

    File.write!(tmp_path, source)

    assert {:ok, %{modules: modules}} =
             JidoBuilderCodegen.Compiler.compile([tmp_path])

    assert Generated.ActionInjection in modules

    File.rm!(tmp_path)
  end

  test "compiles curated action block", %{queue: queue} do
    request = %{
      workspace_id: 1,
      actor: "test",
      blocks: [
        %{
          type: :action,
          module: "Generated.ActionOne",
          name: "a1",
          description: "generated action"
        }
      ]
    }

    assert {:ok, %{modules: [Generated.ActionOne], warnings: []}} =
             CompileQueue.enqueue(queue, request)
  end

  test "compile rollback restores previous file contents", %{queue: queue, tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "broken.ex")
    original = "defmodule Broken do\n  def ok, do: :ok\nend\n"
    File.write!(file, original)

    # First block writes broken.ex (overwriting original); second block fails
    # the FileWriter path-sandbox check, causing write_blocks to return
    # {:error, %{errors: [...], writes: [first_write]}}.  The run_compile else
    # branch then calls rollback/1 on those writes, restoring broken.ex.
    request = %{
      blocks: [
        %{type: :action, module: "Broken", name: "a1", description: "valid"},
        %{type: :action, module: "../escape", name: "bad", description: "escape"}
      ]
    }

    assert {:error, %{errors: [_ | _]}} = CompileQueue.enqueue(queue, request)
    assert File.read!(file) == original
  end

  test "sandbox path enforcement blocks escape attempts" do
    assert {:error, :path_outside_generated_lib} = FileWriter.write("../escape.ex", "bad")
  end
end
