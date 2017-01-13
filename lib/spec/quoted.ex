defmodule Spec.Quoted do
  alias Spec.Mismatch

  def pipe(value, conformer) do
    Spec.Conformer.conform(conformer, value)
  end

  def quoted(quoted) do
    quoted_expr(quoted)
  end

  defp quoted_expr({a, b}) do
    quoted_expr({:{}, [], [a, b]})
  end

  defp quoted_expr(quoted = {:%{}, _, keyword}) do
    keyword = for {k, v} <- keyword, do: {quoted(k), quoted(v)}
    expr = quote do
      Spec.Enum.keyword(unquote(keyword), %{})
    end
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted) when is_list(quoted) do
    if Keyword.keyword?(quoted) do
      keyword = for {k, v} <- quoted, do: {quoted(k), quoted(v)}
      expr = quote do
        Spec.Enum.keyword(unquote(keyword), [])
      end
      quoted_fn(expr, quoted)
    else
      args = Enum.map(quoted, &quoted/1)
      expr = quote do
        Spec.Enum.list(unquote(args))
      end
      quoted_fn(expr, quoted)
    end
  end

  defp quoted_expr(quoted = {:{}, _, args}) do
    args = Enum.map(args, &quoted/1)
    expr = quote do
      Spec.Enum.tuple(unquote(args))
    end
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted = {{:., _, _}, _, _}) do
    quoted_fn(quoted, quoted)
  end

  defp quoted_expr(quoted = {:::, _, [{name, _, x}, arg]}) when is_atom(name) and is_atom(x) do
    conformer = quoted({name, arg})
    expr = quote do
      fn value ->
        {unquote(name), value} |> Spec.Quoted.pipe(unquote(conformer))
      end.()
    end
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted = {:fn, _, _}) do
    quoted_fn(quote(do: unquote(quoted).()), quoted)
  end

  defp quoted_expr(quoted = {:&, _, _}) do
    quoted_fn(quote(do: unquote(quoted).()), quoted)
  end

  defp quoted_expr(quoted = {:sigil_r, _, _}) do
    expr = quote do
      String.match?(unquote(quoted))
    end
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted = {:|>, _, [a, b]}) do
    a = quoted(a)
    expr = quote do
      Spec.Quoted.pipe(unquote(a))
      |> case do
        {:ok, conformed} -> conformed |> unquote(b)
        other -> other
      end
    end
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted = {:and, _, [a, b]}) do
    {a, b} = {quoted(a), quoted(b)}
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
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted = {:or, _, [a, b]}) do
    {a, b} = {quoted(a), quoted(b)}
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
    quoted_fn(expr, quoted)
  end

  defp quoted_expr(quoted = {a, _, args}) when is_atom(a) and is_list(args) do
    if String.match?(to_string(a), ~r/^\w/) do
      quoted_fn(quoted, quoted)
    else # operators
      quoted
    end
  end

  defp quoted_expr(x) when is_atom(x) or is_number(x) or is_binary(x) do
    expr = quote do
      case do
        unquote(x) = v -> {:ok, v}
        v -> Mismatch.error(subject: v, reason: "does not match", expr: unquote(x))
      end
    end
    quoted_fn(expr, x)
  end

  defp quoted_fn(conformer = {_, _, _}, quoted) do
    escaped = Macro.escape(quoted)
    quote do
      %Spec.QuotedConformer{
        quoted: unquote(escaped),
        conformer: fn value -> value |> unquote(conformer) end,
      }
    end
  end

  defp key_quoted(quoted) do
    quoted
    |> Macro.postwalk(fn
      x when is_atom(x) ->
        quote(do: Spec.Enum.has_key?(unquote(x))) |> quoted()
      {x, _, y} when x in [:and, :or] ->
        quote(do: Spec.Enum.has_key?({unquote(x), unquote_splicing(y)})) |> quoted()
      _ ->
        raise "only atoms and `and`/`or` operations are supported inside keys()"
    end)
  end

  def keys(opts) do
    %{required: required,
      optional: optional} =
      %{required: [], optional: []}
      |> Map.merge(Map.new(opts))
      |> Enum.into(%{}, fn {k,v} -> {k, Enum.map(v, &key_quoted/1)} end)
    quoted = quote do
      Spec.Enum.keys(unquote(required), unquote(optional))
    end
    quoted_fn(quoted, opts)
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
