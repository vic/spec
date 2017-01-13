defmodule Spec.Transform do
  defstruct [:conformer, :unformer]
end

defimpl Spec.Transformer, for: Spec.Transform do
  def conform(%{conformer: conformer}, value) do
    Spec.Conformer.conform(conformer, value)
  end

  def unform(%{unformer: unformer}, value) do
    Spec.Conformer.conform(unformer, value)
  end
end
