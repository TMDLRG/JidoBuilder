defmodule JidoBuilderWeb.Live.Phase6PolishTest do
  @moduledoc """
  Phase 6 — Polish surfaces: Threads, Memory, Identity, Glossary,
  Onboarding, Debug, Error Policy, Orphans+Adoption.
  """
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Threads explorer", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/threads")
    assert html =~ "Threads"
  end

  test "renders Memory spaces", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/memory")
    assert html =~ "Memory"
  end

  test "renders Identity profiles", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/identity")
    assert html =~ "Identity"
  end

  test "renders Glossary", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/glossary")
    assert html =~ "Glossary"
  end

  test "renders Onboarding walkthrough", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/onboarding")
    assert html =~ "Onboarding" or html =~ "Welcome"
  end

  test "renders Debug panel", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/debug")
    assert html =~ "Debug"
  end

  test "renders Error Policy editor", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/error-policy")
    assert html =~ "Error Policy"
  end

  test "renders Orphans + Adoption view", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/orphans")
    assert html =~ "Orphan"
  end
end
