defmodule JidoBuilderWeb.Live.GuideV2Test do
  @moduledoc "Gap 2 — Guide v2 sections test."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "guide renders all v2 sections in TOC", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/guide")

    for section <- ["Active Inference", "LLM Agents", "Agent Factory",
                     "Notebook", "Solutions", "Template Library"] do
      assert html =~ section, "Missing guide section: #{section}"
    end
  end

  test "guide renders v2 content blocks", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/guide")

    # Check child section IDs exist
    assert html =~ "what-is-active-inference"
    assert html =~ "configuring-llm-provider"
    assert html =~ "composing-templates"
    assert html =~ "writing-code-cells"
    assert html =~ "deploying-business-solution"
    assert html =~ "browsing-installing-templates"
  end
end
