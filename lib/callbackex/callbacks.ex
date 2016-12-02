defmodule Callbackex.Callbacks do
  @moduledoc """
  Compile callback configs into a callback call

  """

  alias Callbackex.Callback
  alias Callbackex.Context

  @type callback_config_t :: {Callback.t, Keyword.t} | {atom, Keyword.t}

  @type callbacks :: [callback_config_t | [callback_config_t]]

  @type callback_call :: (module, any -> Context.t)

  @doc """
  Compiles a callback call for given callback configs

  Each element of the callback config has the form:
  ```
  {callback_name, options}
  ```

  The function returns the quoted callback call
  """
  @spec compile(callbacks) :: Macro.t
  def compile(callback_configs) do
    context = quote do: context
    call = callback_configs |> Enum.reduce(context, &quote_callback(init_callback(&1), &2))
    quote do
      fn module, value ->
        context = Callbackex.Context.build(module, value)
        case unquote(call) do
          %{value: value, result: nil} = context -> %{context | result: {:ok, value}}
          context -> context
        end
      end
    end
  end

  defp quote_callback({callback_type, callback, opts}, acc) do
    call = quote_callback_call(callback_type, callback, opts)
    quote do
      case unquote(call) do
        {:ok, value} ->
          context = %{context | value: value}
          unquote(acc)
        {:error, error} = error ->
          %{context | result: error}
        message ->
          raise "expect callback #{inspect unquote(callback)} to return either {:ok, value} or {:error, error} but got #{inspect message}"
      end
    end
  end

  defp quote_callback_call(:module, callback, opts) do
    quote do: unquote(callback).call(context.value, unquote(Macro.escape(opts)))
  end

  defp quote_callback_call(:function, callback, opts) do
    quote do: unquote(callback)(context.value, unquote(Macro.escape(opts)))
  end

  defp init_callback({callback, opts}) do
    case Atom.to_char_list(callback) do
      ~c"Elixir." ++ _ -> init_module_callback(callback, opts)
      _                -> init_fun_callback(callback, opts)
    end
  end

  defp init_module_callback(callback, opts) do
    initialized_opts = callback.init(opts)
    if function_exported?(callback, :call, 2) do
      {:module, callback, initialized_opts}
    else
      raise ArgumentError, "#{inspect callback} callback must implement call/2"
    end
  end

  defp init_fun_callback(callback, opts) do
    {:function, callback, opts}
  end
end