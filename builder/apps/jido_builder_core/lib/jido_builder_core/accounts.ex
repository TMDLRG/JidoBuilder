defmodule JidoBuilderCore.Accounts do
  @moduledoc """
  Context module for the local single-user authentication system
  introduced in Work Item 7.13. Persists users with PBKDF2-hashed
  passwords and opaque session tokens.
  """
  import Ecto.Query, only: [from: 2]

  alias JidoBuilderCore.Accounts.{User, UserToken}
  alias JidoBuilderCore.Repo

  @doc """
  Creates a user with the given attributes. `password` is hashed with
  PBKDF2 before insertion.
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Looks up a user by email. Returns `nil` when no record is found.
  """
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Returns the user iff the supplied password matches. Runs a dummy
  PBKDF2 verification when the email is unknown so the caller cannot
  time-side-channel the existence of the account.
  """
  @spec get_user_by_email_and_password(String.t(), String.t()) :: User.t() | nil
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    if User.valid_password?(user, password), do: user, else: nil
  end

  @doc """
  Issues a fresh session token for the given user and persists it.
  Returns the raw token bytes — callers must store this in the browser
  session under the `:user_token` key.
  """
  @spec generate_user_session_token(User.t()) :: binary()
  def generate_user_session_token(%User{} = user) do
    {token, struct} = UserToken.build_session_token(user)
    {:ok, _record} = Repo.insert(struct)
    token
  end

  @doc """
  Looks up the user associated with the supplied session token. Returns
  `nil` when the token is missing, invalid, or was revoked.
  """
  @spec get_user_by_session_token(binary() | nil) :: User.t() | nil
  def get_user_by_session_token(nil), do: nil

  def get_user_by_session_token(token) when is_binary(token) do
    context = UserToken.session_context()

    query =
      from t in UserToken,
        join: u in User,
        on: u.id == t.user_id,
        where: t.token == ^token and t.context == ^context,
        select: u

    Repo.one(query)
  end

  @doc """
  Revokes a session token, typically on logout.
  """
  @spec delete_user_session_token(binary() | nil) :: :ok
  def delete_user_session_token(nil), do: :ok

  def delete_user_session_token(token) when is_binary(token) do
    context = UserToken.session_context()

    Repo.delete_all(
      from t in UserToken, where: t.token == ^token and t.context == ^context
    )

    :ok
  end
end
