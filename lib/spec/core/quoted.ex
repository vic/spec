defmodule Spec.Quoted do
  @doc false # internal API

  alias Spec.Mismatch

  def spec(conformer, unformer \\ quote(do: fn x -> x end)) do
    conformer = conformer(conformer)
    unformer = conformer(unformer)
    quote bind_quoted: [conformer: conformer, unformer: unformer] do
      %Spec.Transform{conformer: conformer, unformer: unformer}
    end
  end

  def pipe(value, conformer) do
    Spec.Conformer.conform(conformer, value)
  end

  # Transform a quoted expression into a QuotedConformer
  def conformer(quoted) do
    quoted_expr(quoted)
  end

  defp quoted_expr(quoted = {:_, _, x}) when is_atom(x) do
    quote do
      fn x -> {:ok, x} end
    end
  end

  defp quoted_expr(quoted = {:%{}, _, keyword}) do
    keyword = for {k, v} <- keyword, do: {conformer(k), conformer(v)}
    expr = quote do
      Spec.Enumerable.keyword(unquote(keyword), %{})
    end
    quoted_conformer(expr, quoted)
  end

  defp quoted_expr(quoted) when is_list(quoted) do
    if Keyword.keyword?(quoted) do
      keyword = for {k, v} <- quoted, do: {conformer(k), conformer(v)}
      expr = quote do
        Spec.Enumerable.keyword(unquote(keyword), [])
      end
      quoted_conformer(expr, quoted)
    else
      args = Enum.map(quoted, &conformer/1)
      expr = quote do
        Spec.Enumerable.list(unquote(args))
      end
      quoted_conformer(expr, quoted)
    end
  end

  defp quoted_expr({a, b}) do
    quoted_expr({:{}, [], [a, b]})
  end

  defp quoted_expr(quoted = {:{}, _, args}) do
    args = Enum.map(args, &conformer/1)
    expr = quote do
      Spec.Enumerable.tuple(unquote(args))
    end
    quoted_conformer(expr, quoted)
  end

  defp quoted_expr(quoted = {{:., _, _}, _, _}) do
    quoted_conformer(quoted, quoted)
  end

  defp quoted_expr(quoted = {:::, _, [tag, arg]}) do
    conformer = conformer(arg)
    expr = quote do
      fn value ->
        tag = unquote(tag)
        value
        |> Spec.Quoted.pipe(unquote(conformer))
        |> case do
            {:ok, conformed} -> {tag, conformed}
            {:error, mismatch = %Mismatch{at: nil}} ->
              {:error, %{mismatch | at: tag}}
            error -> error
          end
      end.()
    end
    quoted_conformer(expr, quoted)
  end

  defp quoted_expr(quoted = {:fn, _, _}) do
    quoted_expr(quote do: unquote(quoted).())
  end

  defp quoted_expr(quoted = {:|>, _, [a, b]}) do
    a = conformer(a)
    expr = quote do
      Spec.Quoted.pipe(unquote(a))
      |> case do
        {:ok, conformed} -> conformed |> unquote(b)
        other -> other
      end
    end
    quoted_conformer(expr, quoted)
  end

  defp quoted_expr(quoted = {:and, _, [a, b]}) do
    {a, b} = {conformer(a), conformer(b)}
    expr = quote do
      fn value ->
        Spec.Quoted.pipe(value, unquote(a))
        |> case do
          {:ok, conformed} ->
            Spec.Quoted.pipe(conformed, unquote(b))
          {:error, e} ->
            Mismatch.error(subject: value,
              reason: {"does not match all alternatives", [e]},
              expr: unquote(Macro.escape(quoted)))
        end
      end.()
    end
    quoted_conformer(expr, quoted)
  end

  defp quoted_expr(quoted = {:or, _, [a, b]}) do
    {a, b} = {conformer(a), conformer(b)}
    expr = quote do
      fn value ->
        Spec.Quoted.pipe(value, unquote(a))
        |> case do
          {:ok, conformed} -> {:ok, conformed}
          {:error, _} ->
            Spec.Quoted.pipe(value, unquote(b))
            |> case do
                {:ok, _} = ok -> ok
                {:error, _} ->
                   Mismatch.error(subject: value,
                     reason: "does not match any alternative",
                     expr: unquote(Macro.escape(quoted)))
              end
        end
      end.()
    end
    quoted_conformer(expr, quoted)
  end

  defp quoted_expr(quoted = {a, _, args}) when is_atom(a) and is_list(args) do
    name = to_string(a)
    cond do
      String.match?(name, ~r/^sigil_/) -> quoted
      String.match?(name, ~r/^\w/) -> quoted_conformer(quoted, quoted)
      :else -> quoted
    end
  end

  defp quoted_expr(expr) do
    expr
  end

  def quoted_conformer(conformer = {_, _, _}, quoted) do
    escaped = Macro.escape(quoted)
    quote do
      %Spec.QuotedConformer{
        quoted: unquote(escaped),
        conformer: fn value -> value |> unquote(conformer) end
      }
    end
  end

  def result(true, value, _quoted), do: {:ok, value}
  def result({:ok, _conformed} = conformed, _value, _quoted), do: conformed

  def result(false, value, quoted) do
    Mismatch.error(
      reason: "does not satisfy predicate",
      subject: value,
      expr: quoted)
  end

  def result({:error, miss = %Mismatch{subject: nil}}, value, quoted) do
    {:error, %Mismatch{ miss | subject: value, expr: quoted }}
  end

  def result({:error, miss = %Mismatch{}}, _, _) do
    {:error, miss}
  end

  def result(conformed, _value, _quoted) do
    {:ok, conformed}
  end
end
