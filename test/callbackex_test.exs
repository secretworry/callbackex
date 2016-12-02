defmodule CallbackexTest do
  use ExUnit.Case

  defmodule ModuleCallback do
    use Callbackex.Callback

    def call(list, opts), do: {:ok, [{__MODULE__, opts} | list]}
  end

  defmodule Sample do

    use Callbackex, [:order_test, :module_test]

    callbacks do
      order_test :do_order_test
      order_test :do_order_test, sequence: 0
      order_test :do_order_test, sequence: 1

      module_test ModuleCallback
      module_test ModuleCallback, test: "test"
    end

    def do_order_test(list, opts), do: {:ok, [{:do_order_test, opts}|list]}

    def call_order_test do
      invoke_callback(:order_test, [])
    end

    def call_module_test do
      invoke_callback(:module_test, [])
    end
  end

  test "should export __callbackex__(:callbacks)" do
    #assert Sample.__callbackex__(:callbacks) == ~w{before_create after_create}a
  end

  test "should call callbacks in defined order" do
    assert Sample.call_order_test()
        == {:ok, [do_order_test: [sequence: 1], do_order_test: [sequence: 0], do_order_test: []]}
  end

  test "should call module callback" do
    assert Sample.call_module_test()
        == {:ok, [{CallbackexTest.ModuleCallback, [test: "test"]}, {CallbackexTest.ModuleCallback, []}]}
  end

  test "should raise error for illegal callback definition" do
    assert_raise ArgumentError, "Illegal callback declareration [:do_method, :a, :b]", fn ->
      defmodule IllegalDefinition do
        use Callbackex, [:illegal_callback]
        callbacks do
          illegal_callback :do_method, :a, :b
        end
      end
    end
  end
end
