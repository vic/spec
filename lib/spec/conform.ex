defmodule Spec.Conform do
  def ok?({:ok, _}), do: true
  def ok?(_), do: false

  def error?({:error, _}), do: true
  def error?(_), do: false

  defmacro keys(map_or_kw, opts) do
    Spec.Enum.keys_conform(map_or_kw, opts)
  end
end
