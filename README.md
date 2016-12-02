# Callbackex

Define and execute callbacks with ease in Elixir

## Installation

  Add `callbackex` to your list of dependencies in `mix.exs`:

    ```elixir
    # use the stable version
    def deps do
      [{:callbackex, "~> 0.1"}]
    end
    
    # use the latest version
    def deps do
      [{:callbackex, github: "secretworry/callbackex", branch: "master"}]
    end
    ```

## Quick Example

  ```elixir
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

## Callbacks

Callbackex supports two kinds of callback: function callback and module callback

A callback callback receives a value and a set of options as arguments and return next value

  ```elixir
  def check_title(params, %{limit: 10}) do
    if params["title"] |> String.length > 10 do
      {:error, "Illegal title"}
    else
      {:ok, params}
    end
  end
  ```

A module callback provides an `init/1` function to initialize options and implement the `call/2` function, receiving the
value to process and the initialized options, and return the value for further processing

  ```elixir
  defmodule IndexCallback do
    def init(opts), do: %{index: Keyword.fetch!(opts, :index), type: Keyword.fetch!(opts, :type)}
    
    def call(model, %{index: index, type: type}) do
      # I'm working on the ElasticSearch wrapper called Elaxto :)
      Elaxto.index(type, model) |> Exlato.run(index: index)
    end
  end
  ```

## Usage

To define callbacks for you module:
  1. You just need to `use Callbackex` in your module and provide callback names as opts.
    For example, I want to define callbacks `before_create`, `after_create` in my `PostProcessor`
    ```elixir
      defmodule PostProcessor do
        use Callbackex, ~w{before_create after_create}a
      end
    ```
    
  2. You need to define a `callbacks` block in your module with the macro `callbacks`.
     In the macro you can define your callbacks like this:
     ```
     callback_name calback_fun_or_module [callback_opts]
     ```
     For example, I want to add callback to check params before creating post, and to index post after creating:
     ```elixir
     callbacks do
       before_create :check_params, title: %{max_length: 10}
       after_create IndexCallback, index: :post_index, type: :post
     end
     ```
     
  3. After defined all the callbacks, you can use the `invoke_callback(callback_name, value)` in your methods.
     ```elixir
     def create(params) do
       with {:ok, params} <- invoke_callback(:before_create, params),
            {:ok, post}   <- do_creat_post(params),
            {:ok, post}   <- invoke_callback(:after_create, params),
        do: {:ok, post}
     end
     ```
     
## License

Callbackex source code is released under Apache 2 License. Check LICENSE file for more information.
      
    



