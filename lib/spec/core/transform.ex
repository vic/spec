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


defimpl Spec.Conformer, for: Spec.Transform do
  def conform(transform, value) do
    Spec.Conformer.conform(transform.conformer, value)
  end
end
