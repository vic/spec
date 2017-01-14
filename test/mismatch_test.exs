defmodule Spec.MismatchTest do
  use ExUnit.Case
  doctest Spec.Enum

  use Spec
  alias Spec.Mismatch

  defmacro assert_equal_quoted(expected, quoted) do
    quote do
      assert Macro.to_string(unquote(expected)) == Macro.to_string(unquote(Macro.escape(quoted)))
    end
  end

  describe "fields" do
    test "on predicate failure" do
      {:error, mismatch = %Mismatch{}} = conform(is_number(), :a)
      assert mismatch.subject == :a
      assert mismatch.reason  == "does not satisfy predicate"
      assert_equal_quoted mismatch.expr, is_number()
      assert mismatch.at == nil
      assert mismatch.in == nil
    end

    test "on nested predicate failure on list item" do
      {:error, mismatch = %Mismatch{}} = conform([is_number()], ["hello"])
      assert mismatch.subject == "hello"
      assert mismatch.reason  == "does not satisfy predicate"
      assert_equal_quoted mismatch.expr, is_number()
      assert mismatch.at == 0
      assert mismatch.in.subject == ["hello"]
    end

  end

  describe "to_string" do
    defp rstrip(string) do
      String.replace_suffix(string, "\n", "")
    end

    test "on predicate failure" do
      {:error, mismatch = %Mismatch{}} = conform(is_number(), :a)
      assert to_string(mismatch) == """
      `:a` does not satisfy predicate `is_number()`
      """ |> rstrip
    end

    test "on nested predicate failure on list item" do
      {:error, mismatch = %Mismatch{}} = conform([is_number()], ["hello"])
      assert to_string(mismatch) == """
      `"hello"` does not satisfy predicate `is_number()`

      at `0` in `["hello"]`
      """ |> rstrip
    end

    test "on invalid keyword values" do
      {:error, mismatch = %Mismatch{}} = conform([a: 2], [a: 1])
      assert to_string(mismatch) == """
      Inside `[a: 1]`, one failure:

      (failure 1) at `:a`

        `1` does not match `2`
      """ |> rstrip
    end

    test "on invalid or" do
      {:error, mismatch = %Mismatch{}} = conform(is_atom() or is_binary() or is_list(), 2)
      assert to_string(mismatch) == """
      `2` does not match any alternative `is_atom() or is_binary() or is_list()`
      """ |> rstrip
    end

    test "on invalid and" do
      {:error, mismatch = %Mismatch{}} = conform(is_number() and is_binary() and is_list(), 2)
      assert to_string(mismatch) == """
      `2` does not match all alternatives `is_number() and is_binary() and is_list()`

      (failure 1)

        `2` does not satisfy predicate `is_binary()`
      """ |> rstrip
    end

    test "on invalid tuple" do
      {:error, mismatch = %Mismatch{}} = conform({1}, [1])
      assert to_string(mismatch) == """
      `[1]` is not a tuple
      """ |> rstrip
    end

    test "on invalid tuple size" do
      {:error, mismatch = %Mismatch{}} = conform({1}, {1, 2})
      assert to_string(mismatch) == """
      `{1, 2}` does not have length 1
      """ |> rstrip
    end

    test "on missing required key" do
      {:error, mismatch = %Mismatch{}} = conform(keys(required: [:b, :a]), %{b: 1})
      assert to_string(mismatch) == """
      `%{b: 1}` does not have key `[:a]`
      """ |> rstrip
    end

    test "on invalid keyword keys with or operator" do
      assert {:error, mismatch} = conform(keys(required: [:d or :c]), [a: 1])
      assert to_string(mismatch) == """
      `[a: 1]` does not have any of keys `[:d, :c]`
      """ |> rstrip
    end

    test "on invalid one_or_more" do
      assert {:error, mismatch} = conform(one_or_more(is_integer()), [])
      assert to_string(mismatch) == """
      `[]` does not have min length of 1
      """ |> rstrip
    end

    test "on invalid one_or_more match" do
      assert {:error, mismatch} = conform(one_or_more(is_integer()), ["a"])
      assert to_string(mismatch) == """
      `"a"` does not satisfy predicate `is_integer()`
      """ |> rstrip
    end

    test "on invalid zero_or_one match" do
      assert {:error, mismatch} = conform(zero_or_one(is_integer()), ["a"])
      assert to_string(mismatch) == """
      `"a"` does not satisfy predicate `is_integer()`
      """ |> rstrip
    end

    test "on invalid zero_or_one size" do
      assert {:error, mismatch} = conform(zero_or_one(is_integer()), [1, 2])
      assert to_string(mismatch) == """
      `[1, 2]` does not have max length of 1
      """ |> rstrip
    end

    test "on many with fail_fast off" do
      assert {:error, mismatch} = conform(many(is_function(), fail_fast: false), [1, 2])
      assert to_string(mismatch) == """
      `[1, 2]` items do not conform

      (failure 1)

        `1` does not satisfy predicate `is_function()`

      (failure 2)

        `2` does not satisfy predicate `is_function()`
      """ |> rstrip
    end

    test "on many with stream max" do
      assert {:error, mismatch} = conform(many(is_number(), max: 3), Range.new(1, 10))
      assert to_string(mismatch) == """
      `1..10` does not have max length of 3
      """ |> rstrip
    end

    test "on many with stream min" do
      assert {:error, mismatch} = conform(many(is_number(), min: 10), Range.new(1, 3))
      assert to_string(mismatch) == """
      `1..3` does not have min length of 10
      """ |> rstrip
    end
  end

end
