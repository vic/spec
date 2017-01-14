defmodule Spec.Regex do

  @moduledoc """
  Provides regex combinators for conformers.
  """

  @at_kernel [context: Elixir, import: Kernel]

  defmacro cat(value, named_conforms) do
    tagged = for {name, expr} <- named_conforms,
      do: {:::, @at_kernel, [name, expr]}
    quoted_conformer(value, tagged)
  end

  defmacro alt(value, named_conforms) do
    tagged = for {name, expr} <- named_conforms,
      do: {:::, @at_kernel, [name, expr]}
    ored = Enum.reduce(Enum.reverse(tagged), fn a, b ->
      {:or, @at_kernel, [a, b]}
    end)
    quoted = quote do: unquote(ored) |> List.wrap
    quoted_conformer(value, quoted)
  end

  defmacro one_or_more(value, expr, opts \\ []) do
    repeat_conformer(value, expr, [min: 1, max: nil] ++ opts)
  end

  defmacro zero_or_more(value, expr, opts \\ []) do
    repeat_conformer(value, expr, [min: 0, max: nil] ++ opts)
  end

  defmacro zero_or_one(value, expr, opts \\ []) do
    repeat_conformer(value, expr, [min: 0, max: 1] ++ opts)
  end

  defmacro many(value, expr, opts \\ []) do
    repeat_conformer(value, expr, opts)
  end

  defp repeat_conformer(value, expr, opts) do
    opts = Map.merge(%{min: 0, max: nil, fail_fast: true}, Map.new(opts))
    opts = {:%{}, [], Enum.into(opts, [])}
    conf = Spec.Quoted.conformer(expr)
    quoted_conformer(value, quote do:
      Spec.Enum.repeat(unquote(conf), unquote(opts)))
  end

  defp quoted_conformer(value, expr) do
    conf = Spec.Quoted.conformer(expr)
    quote do
      Spec.Quoted.pipe(unquote(value), unquote(conf))
    end
  end
end
