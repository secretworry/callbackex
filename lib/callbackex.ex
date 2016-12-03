defmodule Callbackex do
  @moduledoc """
  Define a `Callbackex`

  A callbackex is used to define, organize and invoke callbacks

  # Example
  ```
  defmodule UserProcessor do
    # Use Callbackex
    use Callbackex, :before_create, :after_create

    # Define callbacks
    callbacks do
      before_create :check_ip
      before_create User.ValidateName, limit: 10
      after_create Indexer, index: :user
      after_create AuditLog, operation: :create
    end

    # Use callbacks
    def create(params) do
      with {:ok, params} <- invoke_callback(:before_create, params),
           {:ok, user} <- do_create_user(params),
           {:ok, user} <- invoke_callback(:after_create, user) do
        {:ok, user}
      end
    end
  end
  ```

  # Reflection
  Any callbackex module will generate the __callbackex__ function that can be used for runtime introspection of the callbacks

  * `__callbackex__(:callbacks)` - Returns the callback names defined
  * `__callbackex__(:callback, callback)` - Returns the callback call corresponding to given callback

  """

  @callbacks :callbackex_callbacks
  @callback_registry :callbackex_registry

  alias Callbackex.Callbacks

  defmacro __using__(opts) do
    module = __CALLER__.module
    Module.register_attribute module, @callbacks, accumulate: false, persist: false
    Module.register_attribute module, @callback_registry, accumulate: false, persist: false
    Module.put_attribute module, @callbacks, opts |> Macro.expand(__CALLER__)
    Module.put_attribute module, @callback_registry, %{}
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__)

      def invoke_callback(callback, value) do
        context = Callbackex.do_invoke_callback(__MODULE__, callback, value)
        context.result
      end
    end
  end

  @spec callbacks(Macro.t) :: Macro.t
  defmacro callbacks([do: block]) do
    expand(__CALLER__.module, block)
  end

  @spec do_invoke_callback(module, atom, any) :: Callbackex.Context.t
  def do_invoke_callback(module, callback, value) do
    call = module.__callbackex__(:callback, callback)
    call.(module, value)
  end

  defp expand(module, block) do
    callbacks = Module.get_attribute(module, @callbacks) |> Enum.map(&({&1, []})) |> Enum.into(%{})
    {_, callbacks} =
      Macro.prewalk(block, callbacks, fn
        {_, _, _} = ast, callbacks ->
          try_register_callback(ast, callbacks)
        ast, callbacks ->
          {ast, callbacks}
      end)
    init_value = quote do
      Module.get_attribute(__MODULE__, unquote(@callback_registry))
    end
    callback_definitions = Enum.reduce(callbacks, init_value, &quote_callback_definitions/2)
    quote do
      Module.put_attribute(__MODULE__, unquote(@callback_registry), unquote(callback_definitions))
    end
  end

  defp try_register_callback({method, _, args} = ast, callbacks) do
    # try to register callbacks in *reversed order*
    if Map.has_key?(callbacks, method) do
      callbacks = Map.update!(callbacks, method, fn
        callback_list -> [check_args(args) | callback_list]
      end)
      {nil, callbacks}
    else
      {ast, callbacks}
    end
  end

  defp check_args([callback, opts]) when (is_atom(callback) or is_tuple(callback)) do
    {callback, opts}
  end

  defp check_args([callback]) when (is_atom(callback) or is_tuple(callback)) do
    {callback, []}
  end

  defp check_args(args) do
    declaration = Macro.to_string(args)
    raise ArgumentError, "Illegal callback declareration #{declaration}"
  end

  defp quote_callback_definitions({callback_name, definitions}, acc) do
    quoted_definitions = Enum.map(definitions, &quote_definition/1)
    quote do
      Map.put(unquote(acc), unquote(callback_name), [unquote_splicing(quoted_definitions)])
    end
  end

  defp quote_definition({callback, opts}) do
    quote do
      {unquote(callback), unquote(opts)}
    end
  end

  defmacro __before_compile__(env) do
    callbacks = Module.get_attribute(env.module, @callbacks)
    callback_registry = Module.get_attribute(env.module, @callback_registry)
    [
      quote do
        def __callbackex__(:callbacks), do: unquote(callbacks)
      end,
      define_callback_calls(callback_registry),
      quote do
        def __callbackex__(:callback, callback), do: raise ArgumentError, "Undefined callback #{inspect callback}"
      end
    ]
  end

  defp define_callback_calls(callback_registry) do
    Enum.map(callback_registry, fn
      {callback, configs} ->
        # The order or configs is *reversed*
        call = Callbacks.compile(configs)
        quote do
          def __callbackex__(:callback, unquote(callback)), do: unquote(call)
        end
   end)
  end
end
