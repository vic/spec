defmodule Spec.QuotedConformer do
  defstruct [:quoted, :conformer]
end

defimpl Spec.Conformer, for: Spec.QuotedConformer do
  def quoted(%{quoted: quoted}), do: quoted
  def conform(%{conformer: conformer, quoted: quoted}, value) do
    value
    |> conformer.()
    |> Spec.Quoted.result(value, quoted)
  end
end
