defmodule Spec do

  @doc false
  defmacro __using__(_) do
    quote do
      import Spec
      import Spec.Conform
      import Spec.Seq
      import Spec.Define
    end
  end

  defmacro conform(quoted, value) do
    spec = Spec.Quoted.spec(quoted)
    quote bind_quoted: [spec: spec, value: value] do
      Spec.Protocol.conform(spec, value)
    end
  end

  defmacro valid?(spec, value) do
    quote do
      conform(unquote(spec), unquote(value))
      |> Spec.Conform.ok?
    end
  end
end
