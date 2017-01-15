defmodule Spec.DefspecTest do
  use ExUnit.Case

  use Spec

  describe "defspec" do
    def smart?(iq) when iq > 200, do: true
    def smart?(_), do: false

    defspec nerd, do: %{iq: smart?()}

    test "can be called using conform" do
      assert {:ok, %{iq: 201}} = conform(nerd(), %{iq: 201})
    end

    test "called directly also conforms" do
      assert {:ok, %{iq: 201}} = nerd(%{iq: 201})
    end

    test "called as predicate returns boolean" do
      assert true = nerd?(%{iq: 201})
    end

    test "called with bang returns conformed value only" do
      assert %{iq: 201} = nerd!(%{iq: 201})
    end

    test "called with bang raises on malformed value" do
      assert_raise Spec.Mismatch, fn -> nerd!(%{iq: 2}) end
    end
  end

  describe "defspecp" do
    defspecp kw2, do: is_list() and many({is_atom(), _}, min: 2, max: 2)
    defspecp hello, do: :world, include: [:pred, :bang]

    test "can be called using conform" do
      assert {:ok, [a: 1, b: 2]} = conform(kw2(), [a: 1, b: 2])
    end

    test "passing include: generates :pred or :bang versions" do
      assert true == hello?(:world)
      assert :world == hello!(:world)
    end
  end

  describe "first order specs" do
    defspecp foo, do: :foo
    defspecp bar(baz), do: {:bar, baz}
    defspecp bat(baz), do: {:bat, baz.()}
    defspecp moo(x), do: {:moo, x}
    defspecp muu(x), do: {:muu, x.(22)}
    defspecp dos(n), do: n * 2
    defspecp a_map_of(k, v), do: is_map() and many({k, v})

    test "an spec can be parameter for other" do
      assert {:bar, :foo} = conform!(bar(foo()), {:bar, :foo})
    end

    test "an spec can be given a reference of another" do
      assert {:bat, :foo} = conform!(bat(&foo/1), {:bat, :foo})
    end

    test "an spec can be given an spec built with one arg" do
      assert {:moo, 22} = conform!(moo(dos(11)), {:moo, 22})
    end

    test "an spec can be given a reference that expects an arg" do
      assert {:muu, 44} = conform!(muu(&dos/2), {:muu, 44})
    end

    test "a map of atoms to numbers" do
      assert %{a: 1} = conform!(a_map_of(&is_atom/1, &is_number/1), %{a: 1})
    end
  end


  describe "map_of_many example" do
    defspec example_map_of(key_spec, value_spec, options \\ []), do:
    is_map() and many({key_spec, value_spec}, options)

    test "conforms a map" do
      %{a: 1, b: 2} =
        %{a: 1, b: 2}
        |> example_map_of!(&is_atom/1, &is_number/1, min: 2, max: 2)
    end
  end
end
