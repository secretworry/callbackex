# Callbackex

Define and execute callbacks with ease in Elixir

## Installation

  Add `callbackex` to your list of dependencies in `mix.exs`:

    ```elixir
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

