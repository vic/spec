defmodule Spec.FnTest do
  use ExUnit.Case
  use Spec

  alias __MODULE__.{Specs}

  defmodule Specs do
    use Spec

    defspec sum, do:
    fspec(
      args: many(is_integer(), min: 2, max: 2),
      ret: is_integer())
  end

  describe "fspec" do
    test "can be used to conform a function arguments" do
      assert {:ok, 3} == conform(fspec(args: many(is_integer())),
        {&Kernel.+/2, [1, 2]})
    end

    test "fails if arguments mismatch" do
      assert {:error, miss} = conform(fspec(args: many(is_integer(), min: 3)),
        {&Kernel.+/2, [1, 2]})
      assert miss.subject == [1, 2]
      assert miss.reason == "does not have min length of 3"
    end

    test "fails if return value mismatch" do
      assert {:error, miss} = conform(fspec(
            args: many(is_integer()),
            ret: is_integer()
          ),
        {fn a, b -> "#{a}#{b}" end, [1, 2]})
      assert miss.subject == "12"
      assert miss.reason == "does not satisfy predicate"
    end

    test "fails if args and ret relation mismatch" do
      assert {:error, miss} = conform(fspec(
            args: cat(a: is_integer(), b: is_integer()),
            ret: is_integer(),
            fn: &( &1[:args][:a] + &1[:args][:b] == &1[:ret] )
          ),
        {fn a, b -> a + b * 2 end, [1, 2]})
      assert miss.subject == [args: [a: 1, b: 2], ret: 5]
      assert miss.reason == "does not satisfy predicate"
    end

    test "invokes with conformed arguments if given option apply: :conformed" do
      assert {:ok, 8} = conform(fspec(
            apply: :conformed,
            args: [is_integer() |> fn x -> x * 2 end.(),
                   is_integer() |> fn x -> x * 3 end.()]
          ), {&Kernel.+/2, [1, 2]})
    end

    test "returns conformed ret if given option return: :conformed" do
      assert {:ok, "3"} = conform(fspec(
            return: :conformed,
            args: many(is_integer()),
            ret: to_string()
          ), {&Kernel.+/2, [1, 2]})
    end

    test "returns conformed ret if given option return: :conformed_fn" do
      assert {:ok, 30} = conform(fspec(
            return: :conformed_fn,
            args: many(is_integer()),
            fn: fn x -> x[:ret] * 10 end
          ), {&Kernel.+/2, [1, 2]})
    end

  end

  describe "defconform" do
    @fspec &Specs.sum/1
    defconform sum(a, b), do: a + b

    @fspec &Specs.sum!/1
    defconform sum!(a, b), do: a + b

    test "can use defspec to call a kernel method" do
      assert 3 == Specs.sum!({&Kernel.+/2, [1, 2]})
    end

    test "when conformed with bang version returns value" do
      assert 3 == sum!(1, 2)
    end

    test "when conformed with normal version returns ok value" do
      assert {:ok, 3} == sum(1, 2)
    end
  end
end
