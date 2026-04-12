defmodule JidoBuilderCore.Accounts.UserToken do
  @moduledoc """
  Opaque session token issued when a user signs in. Stored as raw bytes
  in the `user_tokens` table and referenced from the browser session.
  """
  use Ecto.Schema

  @session_context "session"
  @rand_size 32

  schema "user_tokens" do
    field :token, :binary
    field :context, :string

    belongs_to :user, JidoBuilderCore.Accounts.User

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @doc "Generates a fresh session token and struct for insertion."
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, context: @session_context, user_id: user.id}}
  end

  def session_context, do: @session_context
end
