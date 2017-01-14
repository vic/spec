defmodule Spec.SpecTest do
  use ExUnit.Case

  use Spec

  describe "conformer" do
    test "returns a function that can conform" do
      spec = conformer(&Integer.to_string/1)
      assert {:ok, "22"} == conform(spec, 22)
    end

    test "returns a function that can unform" do
      unformer = fn str -> {int, _} = Integer.parse(str); int end
      spec = conformer(&Integer.to_string/1, unformer)
      {:ok, conformed} = conform(spec, 22)
      assert {:ok, 22} == unform(spec, conformed)
    end
  end

  describe "valid?" do
    test "returns true if spec matches" do
      assert true == valid?(is_integer(), 22)
    end

    test "returns false on spec mismatch" do
      assert true == valid?(is_integer(), 23)
    end
  end
end
