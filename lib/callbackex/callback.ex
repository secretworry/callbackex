defmodule Callbackex.Callback do
  @moduledoc """
  The Callback specification

  There are two kind of callbacks: function callbacks and module callbacks

  ## Function callbacks
  A function callback is any function that receives a value and a set of options and return a new value.
  Its type signature must be

  `(any, Keyword.t) -> any`

  ## Module callbacks

  A module callback is a module that must export:
  * a `call/2` function to process the value passed in
  * a `init/1` function whick takes a set of options and initialize the callback

  The result of `init/1` is passed to `call/2` as the second argument.

  # Pipeline
  The `Callbackex.Callbacks` provides methods to execute a callback pipeline

  """
  @type t :: module
  @type result_t ::
      {:ok, any}
    | {:error, any}
  @type opts :: any

  @callback init(Keyword.t) :: opts
  @callback call(any, opts) :: result_t

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      def init(opts), do: opts

      defoverridable [init: 1]
    end
  end
end