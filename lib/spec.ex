defmodule Spec do
  alias Spec.{Conform, Conformer}

  @doc false
  defmacro __using__(_) do
    quote do
      import Spec
      import Spec.Seq
    end
  end

  @spec conform(conformer :: Conform.t, value :: any) :: Conform.result
  defmacro conform(quoted, value) do
    conformer = Conformer.quoted(quoted)
    quote bind_quoted: [conformer: conformer, value: value] do
      Conformer.pipe(value, conformer)
    end
  end

  defmacro valid?(spec, value) do
    quote do
      Spec.conform(unquote(spec), unquote(value))
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
    conformer = Conformer.keys(opts)
    quote bind_quoted: [conformer: conformer, map_or_kw: map_or_kw] do
      Conformer.pipe(map_or_kw, conformer)
    end
  end
end
