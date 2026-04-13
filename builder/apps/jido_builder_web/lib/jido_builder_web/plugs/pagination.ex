defmodule JidoBuilderWeb.Plugs.Pagination do
  @moduledoc """
  Shared pagination parser plug.

  Parses `limit` and `offset` query parameters and assigns them to the connection.
  Defaults: limit=50, offset=0. Max limit=100.
  """
  import Plug.Conn

  @default_limit 50
  @max_limit 100
  @default_offset 0

  def init(opts), do: opts

  def call(conn, _opts) do
    limit =
      case conn.params["limit"] do
        nil -> @default_limit
        val -> val |> to_integer() |> max(1) |> min(@max_limit)
      end

    offset =
      case conn.params["offset"] do
        nil -> @default_offset
        val -> val |> to_integer() |> max(0)
      end

    conn
    |> assign(:pagination_limit, limit)
    |> assign(:pagination_offset, offset)
  end

  defp to_integer(val) when is_integer(val), do: val

  defp to_integer(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} -> n
      _ -> 0
    end
  end

  defp to_integer(_), do: 0

  @doc "Apply limit/offset to a list."
  def paginate(list, limit, offset) do
    list
    |> Enum.drop(offset)
    |> Enum.take(limit)
  end
end
