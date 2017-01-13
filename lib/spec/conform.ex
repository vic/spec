defmodule Spec.Conform do
  alias Spec.Quoted

  @spec conform(conformer :: Spec.t, value :: any) :: Spec.result
  defmacro conform(quoted, value) do
    conformer = Quoted.quoted(quoted)
    quote bind_quoted: [conformer: conformer, value: value] do
      Quoted.pipe(value, conformer)
    end
  end

  defmacro valid?(spec, value) do
    quote do
      conform(unquote(spec), unquote(value))
      |> case do
           {:ok, _} -> true
           {:error, _} -> false
         end
    end
  end

  def ok?({:ok, _}), do: true
  def ok?(_), do: false

  def error?({:error, _}), do: true
  def error?(_), do: false

  defmacro keys(map_or_kw, opts) do
    conformer = Quoted.keys(opts)
    quote bind_quoted: [conformer: conformer, map_or_kw: map_or_kw] do
      Quoted.pipe(map_or_kw, conformer)
    end
  end
end

