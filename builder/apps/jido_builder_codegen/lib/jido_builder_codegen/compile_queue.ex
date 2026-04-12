defmodule JidoBuilderCodegen.CompileQueue do
  use GenServer

  alias JidoBuilderCodegen.{BlockSchema, Compiler, FileWriter, Templates}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)

  def enqueue(server \\ __MODULE__, request),
    do: GenServer.call(server, {:compile, request}, :infinity)

  @impl true
  def init(:ok), do: {:ok, %{}}

  @impl true
  def handle_call({:compile, request}, _from, state) do
    result = run_compile(request)
    {:reply, result, state}
  end

  defp run_compile(%{blocks: blocks} = request) do
    with :ok <- validate_blocks(blocks),
         {:ok, writes} <- write_blocks(blocks) do
      case Compiler.compile(Enum.map(writes, & &1.path)) do
        {:ok, diagnostics} ->
          Jido.Discovery.refresh()
          persist_attempt(request, "success", diagnostics, writes)
          {:ok, diagnostics}

        {:error, reason} ->
          rollback(writes)
          reason_with_writes = Map.put(reason, :writes, writes)
          persist_attempt(request, "failed", reason_with_writes, writes)
          {:error, reason_with_writes}
      end
    else
      {:error, reason} = error ->
        rollback(Map.get(reason, :writes, []))
        persist_attempt(request, "failed", reason, Map.get(reason, :writes, []))
        error
    end
  end

  defp validate_blocks(blocks) do
    if Enum.all?(blocks, &BlockSchema.valid?/1),
      do: :ok,
      else: {:error, %{errors: ["invalid block schema"], writes: []}}
  end

  defp write_blocks(blocks) do
    Enum.reduce_while(blocks, {:ok, []}, fn block, {:ok, acc} ->
      rel_path = "#{Macro.underscore(block.module)}.ex"

      with {:ok, source} <- Templates.render(block),
           {:ok, write} <- FileWriter.write(rel_path, source) do
        {:cont, {:ok, [write | acc]}}
      else
        {:error, reason} ->
          {:halt, {:error, %{errors: [inspect(reason)], writes: acc}}}
      end
    end)
    |> case do
      {:ok, writes} -> {:ok, Enum.reverse(writes)}
      error -> error
    end
  end

  defp rollback(writes), do: Enum.each(writes, &FileWriter.restore(&1.path, &1.previous))

  defp persist_attempt(request, status, diagnostics, writes) do
    attrs = %{
      workspace_id: Map.get(request, :workspace_id),
      template_id: Map.get(request, :template_id),
      status: status,
      request: Map.take(request, [:workspace_id, :template_id, :blocks]),
      diagnostics: diagnostics,
      generated_files: Enum.map(writes, & &1.path)
    }

    _ = JidoBuilderCore.Codegen.create_compile_attempt(attrs, Map.get(request, :actor, "codegen"))
    :ok
  rescue
    _ -> :ok
  end
end
