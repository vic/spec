defmodule Spec.DefTest do
  use ExUnit.Case
  use Spec

  alias __MODULE__.{Specs, Sum}

  defmodule Specs do
    use Spec

    defspec sum, do:
    fspec(
      args: many(is_integer(), min: 2, max: 2),
      ret: is_integer())
  end

  defmodule Sum do
    use Spec.Def

    @fspec &Specs.sum!/1
    def sum(a, b), do: a + b
  end

  describe "fn def" do
    test "instruments the def function" do
      assert 3 == Sum.sum(1, 2)
    end

    test "raises if spec does not match" do
      assert_raise Spec.Mismatch, ~r/`:a` does not satisfy predicate/i, fn ->
        Sum.sum(1, :a)
      end
    end
  end
end
