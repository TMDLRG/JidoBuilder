defmodule JidoBuilderCore.Codegen do
  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Codegen.CompileAttempt
  alias JidoBuilderCore.Repo

  @spec create_compile_attempt(map(), term()) ::
          {:ok, CompileAttempt.t()} | {:error, Ecto.Changeset.t()}
  def create_compile_attempt(attrs, actor) do
    %CompileAttempt{}
    |> CompileAttempt.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, "codegen.compile_attempts.create")
  end

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end

  defp maybe_audit(error, _actor, _action), do: error
end
