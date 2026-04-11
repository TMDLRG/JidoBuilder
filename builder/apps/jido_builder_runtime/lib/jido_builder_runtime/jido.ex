defmodule JidoBuilderRuntime.Jido do
  @moduledoc """
  The Jido instance for Jido Builder.

  All runtime agent lifecycle calls route through this supervised instance.
  """

  use Jido, otp_app: :jido_builder
end
