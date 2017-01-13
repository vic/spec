defmodule Spec.Seq do

  @moduledoc """
  Provides regex combinators for matching sequence elements.
  """

  @at_kernel [context: Elixir, import: Kernel]

  defmacro cat(value, named_specs) do
    tagged = for {name, spec} <- named_specs,
      do: {:::, @at_kernel, [{name, [], nil}, spec]}
    quoted_conformer(value, tagged)
  end

  defmacro alt(value, named_specs) do
    tagged = for {name, spec} <- named_specs,
      do: {:::, @at_kernel, [{name, [], nil}, spec]}
    ored = Enum.reduce(Enum.reverse(tagged), fn a, b ->
      {:or, @at_kernel, [a, b]}
    end)
    quoted = quote do: unquote(ored) |> List.wrap
    quoted_conformer(value, quoted)
  end

  defmacro one_or_more(value, spec, opts \\ []) do
    repeat_conformer(value, spec, [min: 1, max: nil] ++ opts)
  end

  defmacro zero_or_more(value, spec, opts \\ []) do
    repeat_conformer(value, spec, [min: 0, max: nil] ++ opts)
  end

  defmacro zero_or_one(value, spec, opts \\ []) do
    repeat_conformer(value, spec, [min: 0, max: 1] ++ opts)
  end

  defmacro many(value, spec, opts \\ []) do
    repeat_conformer(value, spec, opts)
  end

  defp repeat_conformer(value, spec, opts) do
    opts = Map.merge(%{min: 0, max: nil, fail_fast: true}, Map.new(opts))
    opts = {:%{}, [], Enum.into(opts, [])}
    conf = Spec.Quoted.quoted(spec)
    quoted_conformer(value, quote do:
      Spec.Enum.repeat(unquote(conf), unquote(opts)))
  end

  defp quoted_conformer(value, conf) do
    conf = Spec.Quoted.quoted(conf)
    quote do
      Spec.Quoted.pipe(unquote(value), unquote(conf))
    end
  end
end
