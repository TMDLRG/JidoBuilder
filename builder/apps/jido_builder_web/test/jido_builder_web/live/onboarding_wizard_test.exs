defmodule JidoBuilderWeb.Live.OnboardingWizardTest do
  @moduledoc "Story 6.5 — Interactive onboarding wizard."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "mount shows step 1 with workspace creation form", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/onboarding")

    assert html =~ "Step 1"
    assert html =~ "Create a Workspace"
    assert html =~ "onboarding-form"
  end

  test "completing step 1 advances to step 2", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/onboarding")

    html =
      lv
      |> element("#onboarding-form")
      |> render_submit(%{"onboarding" => %{"workspace_name" => "test-ws-#{System.unique_integer([:positive])}"}})

    assert html =~ "Step 2"
    assert html =~ "Template"
  end

  test "completing all steps shows success state", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/onboarding")

    # Step 1
    lv
    |> element("#onboarding-form")
    |> render_submit(%{"onboarding" => %{"workspace_name" => "onb-ws-#{System.unique_integer([:positive])}"}})

    # Step 2 - skip (use next)
    lv |> element("#skip-step") |> render_click()

    # Step 3 - skip
    lv |> element("#skip-step") |> render_click()

    # Step 4 - skip
    html = lv |> element("#skip-step") |> render_click()

    assert html =~ "All Done" || html =~ "Congratulations" || html =~ "complete"
  end
end
