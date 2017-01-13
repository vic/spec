defmodule Spec.Conform do

  defmacro conform(quoted, value) do
    Spec.Quoted.conform(quoted, value)
  end

  defmacro valid?(spec, value) do
    quote do
      conform(unquote(spec), unquote(value))
      |> unquote(__MODULE__).ok?
    end
  end

  def ok?({:ok, _}), do: true
  def ok?(_), do: false

  def error?({:error, _}), do: true
  def error?(_), do: false

  defmacro keys(map_or_kw, opts) do
    Spec.Enum.keys_conform(map_or_kw, opts)
  end
end

