defmodule JidoBuilderCore.Accounts.User do
  @moduledoc """
  Single-user authentication schema backed by PBKDF2-hashed passwords.
  Used only for the local Builder operator login (Work Item 7.13).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          email: String.t() | nil,
          hashed_password: String.t() | nil,
          password: String.t() | nil
        }

  schema "users" do
    field :email, :string
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating or updating a user. Requires `email` and a
  plain `password` (virtual) which is hashed via PBKDF2 on save.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
    |> validate_length(:password, min: 8, max: 128)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = cs) do
    cs
    |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  defp put_password_hash(cs), do: cs

  @doc """
  Verifies that the supplied plaintext password matches the stored PBKDF2
  hash. Runs `no_user_verify/0` when the user is nil to keep response
  time constant regardless of whether the email exists.
  """
  def valid_password?(%__MODULE__{hashed_password: hash}, password)
      when is_binary(hash) and is_binary(password) do
    Pbkdf2.verify_pass(password, hash)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end
end
