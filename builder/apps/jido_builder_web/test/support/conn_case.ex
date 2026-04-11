defmodule JidoBuilderWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint JidoBuilderWeb.Endpoint
      use Phoenix.ConnTest
      import Phoenix.LiveViewTest
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
