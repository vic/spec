defmodule Spec.DefineTest do
  use ExUnit.Case

  use Spec

  describe "defspec" do
    def smart?(iq) when iq > 200, do: true
    def smart?(_), do: false

    defspec nerd %{iq: smart?()}

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
  end
end
