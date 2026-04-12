defmodule Mix.Tasks.JidoBuilder.CreateUser do
  @shortdoc "Creates a local Builder operator user"

  @moduledoc """
  Creates a single-user login account for the local Builder (Work Item 7.13).

  ## Usage

      mix jido_builder.create_user --email you@example.com --password s3cret!!

  ## Options

    * `--email`    — Email address for the new user (required).
    * `--password` — Plain-text password. Must be at least 8 characters.
                     Will be bcrypt-hashed before storage.
  """
  use Mix.Task

  alias JidoBuilderCore.Accounts

  @switches [email: :string, password: :string]

  @impl Mix.Task
  def run(argv) do
    {opts, _rest, _invalid} = OptionParser.parse(argv, strict: @switches)

    email = Keyword.get(opts, :email) || Mix.raise("--email is required")
    password = Keyword.get(opts, :password) || Mix.raise("--password is required")

    Mix.Task.run("app.start")

    case Accounts.create_user(%{email: email, password: password}) do
      {:ok, user} ->
        Mix.shell().info("Created user #{user.email} (id=#{user.id})")

      {:error, changeset} ->
        errors =
          Enum.map_join(changeset.errors, ", ", fn {field, {msg, _}} -> "#{field}: #{msg}" end)

        Mix.raise("Failed to create user — #{errors}")
    end
  end
end
