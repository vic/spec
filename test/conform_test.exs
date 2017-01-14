defmodule Spec.ConformTest do
  use ExUnit.Case

  use Spec
  alias Spec.Mismatch

  describe "conform" do

    test "match anything with placeholder" do
      assert {:ok, "hello"} = conform(_, "hello")
    end

    test "match with is_binary predicate" do
      assert {:ok, "hello"} = conform(is_binary(), "hello")
    end

    test "non matching is_binary predicate" do
      assert {:error, %Mismatch{}} = conform(is_binary(), 22)
    end

    test "match with a partial call" do
      assert {:ok, 22} = conform(Kernel.==(22), 2 * 11)
    end

    def tuple_sum?({a, b}, c) when a + b == c, do: true
    def tuple_sum?(_, _), do: false

    test "match a custom predicate" do
      assert {:ok, {1, 2}} = conform(tuple_sum?(3), {1, 2})
    end

    test "match an anon fn" do
      assert {:ok, "22"} = conform(fn x -> {:ok, to_string(x)} end, 22)
    end

    test "match an anon capture fn" do
      assert {:ok, 22} = conform(&(10 < &1), 22)
    end

    test "match and predicates" do
      assert {:ok, {1, 2}} = conform(is_tuple() and &(tuple_size(&1) == 2), {1, 2})
    end

    test "match or predicates" do
      assert {:ok, 20} = conform(is_atom() or is_number(), 20)
    end

    test "match a tuple" do
      x = {:answer, 42}
      assert {:ok, ^x} = conform({is_atom(), is_number()}, x)
    end

    test "match a tagged value" do
      assert {:ok, {:teen, 19}} = conform(:teen :: &(9 < &1 and &1 < 20), 19)
    end

    test "match tagged or alternatives" do
      a = :foo
      b = :bar
      assert {:ok, {:bar, 20}} = conform((a :: is_atom()) or (b :: is_number()), 20)
    end

    test "match a tuple conforming it into a list" do
      x = {:answer, 42}
      assert {:ok, [:answer, 42]} = conform({is_atom(), is_number()} |> Tuple.to_list, x)
    end

    test "match a list" do
      x = [:answer, 42]
      assert {:ok, ^x} = conform([is_atom(), is_number()], x)
    end

    test "match a list conforming into a map" do
      x = [:answer, 42]
      assert {:ok, m} = conform([:a :: is_atom(), :b :: is_number()] |> Enum.into(%{}), x)
      assert :answer = m.a
      assert 42 = m.b
    end

    test "match string regex" do
      assert {:ok, "Hello"} = conform(~r/hell/i, "Hello")
    end

    test "match string regex with named groups" do
      assert {:ok, %{"foo" => "el"}} = conform(~r/h(?<foo>el)l/i, "Hello")
    end

    test "match ok?" do
      assert {:ok, {:ok, 12}} = conform(ok?(), {:ok, 12})
    end

    test "match error?" do
      assert {:ok, {:error, 12}} = conform(error?(), {:error, 12})
    end

    test "match error? and conform to second elem subject" do
      assert {:ok, 12} = conform(error?() |> elem(1) |> Map.get(:subject), {:error, %{subject: 12}})
    end

  end
end
