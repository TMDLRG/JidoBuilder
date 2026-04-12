defmodule JidoBuilderCore.Vault do
  use Cloak.Vault, otp_app: :jido_builder_core

  # @table_name is injected by the `use Cloak.Vault` macro as
  # :"Elixir.JidoBuilderCore.Vault.Config"

  @doc """
  Reconfigures the vault ciphers at runtime.

  Used during key rotation to swap in a new default cipher and keep the
  previous one as `retired:` so that rows encrypted with the old key can
  still be read and re-encrypted by the rotation task.

  ## Example

      JidoBuilderCore.Vault.reconfigure(
        ciphers: [
          default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V2", key: new_key},
          retired: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: old_key}
        ]
      )
  """
  def reconfigure(new_config) do
    GenServer.call(__MODULE__, {:reconfigure, new_config})
  end

  # Override handle_call to add the :reconfigure clause, then delegate
  # everything else to the macro-generated implementation via super/3.
  def handle_call({:reconfigure, new_config}, _from, _old_config) do
    Cloak.Vault.save_config(@table_name, new_config)
    {:reply, :ok, new_config}
  end

  def handle_call(msg, from, state) do
    super(msg, from, state)
  end
end
