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
end
