defmodule JidoBuilderWeb.HealthController do
  @moduledoc """
  Liveness and readiness probes for container orchestrators.

  /healthz always returns 200 if the BEAM is alive and the endpoint
  is serving. Used by Docker HEALTHCHECK and Kubernetes livenessProbe.

  /readyz returns 200 only when all critical dependencies are up:
  the Repo connection pool, the Jido supervisor instance, and the
  Phoenix.PubSub server. Returns 503 otherwise. Used by
  Kubernetes readinessProbe to withhold traffic until the app is
  fully booted.
  """
  use JidoBuilderWeb, :controller

  def healthz(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  def readyz(conn, _params) do
    checks = %{
      repo: repo_ready?(),
      jido: jido_ready?(),
      pubsub: pubsub_ready?()
    }

    if Enum.all?(checks, fn {_k, v} -> v end) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "ready")
    else
      failing =
        checks
        |> Enum.filter(fn {_k, v} -> not v end)
        |> Enum.map(fn {k, _} -> Atom.to_string(k) end)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(503, "not ready: " <> Enum.join(failing, ", "))
    end
  end

  defp repo_ready? do
    case Ecto.Adapters.SQL.query(JidoBuilderCore.Repo, "SELECT 1", []) do
      {:ok, _} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp jido_ready? do
    Process.whereis(JidoBuilderRuntime.Jido) != nil
  end

  defp pubsub_ready? do
    Process.whereis(JidoBuilder.PubSub) != nil
  end
end
