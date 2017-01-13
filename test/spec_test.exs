defmodule Spec.SpecTest do
  use ExUnit.Case
  doctest Spec.Enum

  use Spec

  describe "valid?" do
    test "returns true if spec matches" do
      assert true == valid?(is_integer(), 22)
    end

    test "returns false on spec mismatch" do
      assert true == valid?(is_integer(), 23)
    end
  end

  describe "conformer" do
    test "returns a function that can conform" do
      spec = conformer(&Integer.to_string/1)
      assert {:ok, "22"} == Spec.Transformer.conform(spec, 22)
    end

    test "returns a function that can unform" do
      unformer = fn str -> {int, _} = Integer.parse(str); int end
      spec = conformer(&Integer.to_string/1, unformer)
      {:ok, conformed} = Spec.Transformer.conform(spec, 22)
      assert {:ok, 22} == Spec.Transformer.unform(spec, conformed)
    end

  end
end
