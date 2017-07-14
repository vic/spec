defmodule Spec.RegexTest do
  use ExUnit.Case

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
    test "matches one" do
      x = [1]
      assert {:ok, ^x} = conform(one_or_more(is_integer()), x)
    end

    test "matches more than one" do
      x = [1, 2]
      assert {:ok, ^x} = conform(one_or_more(is_integer()), x)
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

    test "can operate on tuples" do
      x = {1, 2}
      assert {:ok, ^x} = conform(many(is_integer()), x)
    end

    test "can operate on maps" do
      x = %{"hola" => :mundo}
      assert {:ok, ^x} = conform(many({is_binary(), is_atom()}), x)
    end

  end

  describe "many(as_stream: true)" do
    test "returns a lazy conformed stream of conformed values" do
      x = [33, "hello", 22]
      assert {:ok, s} = conform(many(is_integer(), as_stream: true), x)
      assert [{:ok, 33}, {:error, %{subject: "hello"}}, {:ok, 22}] = Enum.to_list(s)
    end

    test "raises if no minimal size is reached" do
      x = [33, 22]
      assert {:ok, s} = conform(many(is_integer(), min: 10, as_stream: true), x)
      assert_raise Spec.Mismatch, fn -> Enum.to_list(s) end
    end

    test "raises if no maximum size is exceeded" do
      x = [33, 22]
      assert {:ok, s} = conform(many(is_integer(), max: 1, as_stream: true), x)
      assert_raise Spec.Mismatch, fn -> Enum.to_list(s) end
    end

    test "fail_fast: false appends the maximum size error when exceeded" do
      x = [33, 22]
      assert {:ok, s} = conform(many(is_integer(), max: 1, fail_fast: false, as_stream: true), x)
      assert [{:ok, _}, {:error, mismatch}] = Enum.to_list(s)
      assert mismatch.reason =~ ~r/max length of 1/
    end

    test "can operate on tuples" do
      x = {1, 2}
      assert {:ok, s} = conform(many(is_integer(), as_stream: true), x)
      assert [{:ok, 1}, {:ok, 2}] = Enum.to_list(s)
    end

  end

end
