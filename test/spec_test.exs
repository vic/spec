defmodule Spec.SpecTest do
  use ExUnit.Case
  doctest Spec.Enum

  use Spec

  describe "valid?" do
    @tag :skip
    test "returns true if spec matches" do
      nil
    end
  end

end
