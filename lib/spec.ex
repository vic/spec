defmodule Spec do
  @doc false
  defmacro __using__(_) do
    quote do
      import Spec
      import Spec.Conform
      import Spec.Regex
      import Spec.Define
    end
  end

  def conformer(conformer, unformer \\ fn x -> x end) do
    fn
      {:conform, value} ->
        conformer.(value) |> Spec.Quoted.result(value, inspect(conformer))
      {:unform, value} ->
        unformer.(value) |> Spec.Quoted.result(value, inspect(unformer))
    end
  end

  def unform(spec, value) do
    Spec.Transformer.unform(spec, value)
  end

  defmacro conform(spec, value) do
    spec = Spec.Quoted.spec(spec)
    quote bind_quoted: [spec: spec, value: value] do
      Spec.Transformer.conform(spec, value)
    end
  end

  defmacro valid?(spec, value) do
    quote do
      conform(unquote(spec), unquote(value))
      |> Spec.Conform.ok?
    end
  end
end
