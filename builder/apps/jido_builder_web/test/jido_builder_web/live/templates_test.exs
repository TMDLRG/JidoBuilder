defmodule JidoBuilderWeb.Live.TemplatesTest do
  @moduledoc """
  Phase 2.3 + 2.4 — Templates library index + template editor.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Templates}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "tmpl-ws-#{System.unique_integer()}", slug: "tmpl-ws-#{System.unique_integer()}"},
        "test"
      )

    {:ok, tmpl} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "TestAgent",
          slug: "test-agent",
          version: "0.1.0",
          status: "draft"
        },
        "test"
      )

    %{workspace: workspace, template: tmpl}
  end

  describe "2.3 Templates Index" do
    test "lists templates for workspace", %{conn: conn, workspace: ws, template: tmpl} do
      {:ok, _lv, html} = live(conn, ~p"/templates?workspace_id=#{ws.id}")

      assert html =~ "Templates"
      assert html =~ tmpl.name
      assert html =~ tmpl.slug
    end

    test "empty workspace shows no templates", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/templates?workspace_id=999999")

      assert html =~ "Templates"
      assert html =~ "No templates"
    end
  end

  describe "2.4 Template Editor" do
    test "edit form loads template data", %{conn: conn, template: tmpl} do
      {:ok, _lv, html} = live(conn, ~p"/templates/#{tmpl.id}/edit")

      assert html =~ "Edit Template"
      assert html =~ tmpl.name
    end

    test "updating template name persists", %{conn: conn, template: tmpl} do
      {:ok, lv, _html} = live(conn, ~p"/templates/#{tmpl.id}/edit")

      html =
        lv
        |> form("#template-form", template: %{name: "UpdatedAgent"})
        |> render_submit()

      assert html =~ "UpdatedAgent"
    end
  end
end
