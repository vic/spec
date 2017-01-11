defmodule Spec.SeqTest do
  use ExUnit.Case
  doctest Spec.Enum

  use Spec

  describe "cat" do
    test "matches and creates a keyword" do
      x = [1, "foo"]
      {:ok, conformed} = conform(cat(age: is_integer(), name: is_binary()), x)
      assert [age: 1, name: "foo"] == conformed
    end
  end

  describe "alt" do
    test "matches and creates a keyword" do
      x = "foo"
      {:ok, conformed} = conform(
        alt(age: is_integer(), bar: ~r/FOO/i, name: is_binary()), x)
      assert [bar: "foo"] == conformed
    end
  end

  describe "one_or_more" do
    test "matches" do
      x = [1, 2]
      assert {:ok, ^x} = conform(one_or_more(is_integer()), x)
    end
  end

  describe "zero_or_more" do
    test "matches zero" do
      x = []
      assert {:ok, ^x} = conform(zero_or_more(is_integer()), x)
    end

    test "matches more than zero" do
      x = [1, 2]
      assert {:ok, ^x} = conform(zero_or_more(is_integer()), x)
    end
  end

  describe "zero_or_one" do
    test "matches zero" do
      x = []
      assert {:ok, ^x} = conform(zero_or_one(is_integer()), x)
    end

    test "matches on one" do
      x = [1]
      assert {:ok, ^x} = conform(zero_or_one(is_integer()), x)
    end
  end

  describe "many" do
    test "matches zero" do
      x = []
      assert {:ok, ^x} = conform(many(is_integer()), x)
    end

    test "matches more than zero" do
      x = [1, 2]
      assert {:ok, ^x} = conform(many(is_integer()), x)
    end
  end

end
