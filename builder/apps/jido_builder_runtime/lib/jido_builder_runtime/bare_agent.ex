defmodule JidoBuilderRuntime.BareAgent do
  @moduledoc """
  Minimal runtime agent used by the Phase 1 roster hire form when no
  template has been configured. Carries no schema fields; it is a
  no-op agent that can receive and acknowledge signals.

  In Phase 2, the roster will upgrade to template-backed `DynamicAgent`
  instances once the template library screen is wired up.
  """
  use Jido.Agent,
    name: "builder_bare_agent",
    description: "Unconfigured placeholder agent",
    schema: []
end
