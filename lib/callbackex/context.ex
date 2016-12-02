defmodule Callbackex.Context do
  @moduledoc """
  The struct holding context for executing callbacks

  Its fields are:

  * `module` - The module which the callbacks are defined for
  * `value` - The value that being process by callbacks
  """

  @type result_t ::
      {:ok, any}
    | {:error, any}

  @type t :: %__MODULE__{
    module: module,
    value: any,
    result: result_t
  }

  @enforce_fields ~w{module value}a
  defstruct [:module, :value, result: nil]

  def build(module, value) do
    %__MODULE__{module: module, value: value}
  end
end