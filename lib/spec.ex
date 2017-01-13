defmodule Spec do

  @doc false
  defmacro __using__(_) do
    quote do
      import Spec.Conform
      import Spec.Seq
      import Spec.Define
    end
  end

end
