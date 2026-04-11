defmodule JidoBuilderCodegenTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCodegen.CompileQueue

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

  test "rolls back written file when compile fails", %{queue: queue, tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "broken.ex")
    File.write!(file, "defmodule Broken do\n  def ok, do: :ok\nend\n")

    request = %{
      blocks: [
        %{type: :action, module: "Broken", name: "a1", description: "\"\"\""}
      ]
    }

    assert {:error, %{errors: [_ | _]}} = CompileQueue.enqueue(queue, request)
    assert File.read!(file) == "defmodule Broken do\n  def ok, do: :ok\nend\n"
  end

  test "rejects writes outside generated directory", %{queue: queue} do
    request = %{
      blocks: [
        %{type: :unknown, module: "../evil", name: "bad", description: "bad"}
      ]
    }

    assert {:error, %{errors: ["invalid block schema"], writes: []}} =
             CompileQueue.enqueue(queue, request)
  end
end
