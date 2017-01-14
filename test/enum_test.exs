defmodule Spec.EnumTest do
  use ExUnit.Case

  use Spec

  describe "conform" do
    def right(_left, right), do: right
    def indif(a, b), do: String.downcase(to_string(a)) == String.downcase(to_string(b))

    test "match map value predicate" do
      x = %{a: 1}
      assert {:ok, ^x} = conform(%{a: is_number()}, x)
    end

    test "match map key values and conform keys into constants" do
      x = %{"a" => 1, :B => 2, :c => 3}
      assert {:ok, %{foo: 1, bar: 2}} = conform(%{
        indif(:a) |> right(:foo) => is_number(),
        indif(:b) |> right(:bar) => is_number()
      }, x)
    end

    test "match keyword values" do
      x = [a: 1, b: 2]
      assert {:ok, [a: 1]} = conform([a: is_number()], x)
    end

    test "match keyword key values and conforms both to strings" do
      x = [a: 1]
      assert {:ok, [{"a", "1"}]} = conform([{:a |> to_string, is_number() |> to_string}], x)
    end

    test "match a map keys" do
      x = %{a: 1, b: 2, c: 3}
      assert {:ok, conformed} = conform(keys(required: [:a], optional: [:c]), x)
      assert 1 == conformed.a
      assert not Map.has_key?(conformed, :b)
      assert 3 == conformed.c
    end

    test "match a keyword keys" do
      x = [a: 1, b: 2, c: 3, a: 4]
      assert {:ok, conformed} = conform(keys(required: [:a], optional: [:c]), x)
      assert [a: 1, c: 3, a: 4] == Keyword.take(conformed, [:a, :b, :c])
    end

    test "match keyword keys with or operator" do
      x = [a: 1, b: 2, c: 3]
      assert {:ok, conformed} = conform(keys(required: [:d or :c]), x)
      assert [c: 3] = conformed
    end

    test "match keyword keys with and operator" do
      x = [a: 1, b: 2, c: 3]
      assert {:ok, conformed} = conform(keys(required: [:a and :c]), x)
      assert [a: 1, c: 3] = conformed
    end

    test "match keyword keys with or-and operator" do
      x = [a: 1, b: 2, c: 3]
      assert {:ok, conformed} = conform(keys(required: [:d or (:a and :c)]), x)
      assert [a: 1, c: 3] = conformed
    end

  end
end
