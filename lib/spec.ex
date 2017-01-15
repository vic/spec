defmodule Spec do

  @doc false
  defmacro __using__(_) do
    quote do
      import Spec
      import Spec.Fn
      import Spec.Def
      import Spec.Key
      import Spec.Regex
      import Spec.Kernel
    end
  end

  @spec conformer(Spec.Conformer.fun, Spec.Conformer.fun) :: Spec.Transformer.t
  def conformer(conformer, unformer \\ fn x -> x end) do
    %Spec.Transform{conformer: conformer, unformer: unformer}
  end

  @spec unform(Spec.Conformer.quoted, any) :: Spec.Conformer.result
  def unform(spec, value) do
    Spec.Transformer.unform(spec, value)
  end

  @spec conform(Spec.Conformer.quoted, any) :: Spec.Conformer.result
  defmacro conform(spec, value) do
    spec = Spec.Quoted.spec(spec)
    quote bind_quoted: [spec: spec, value: value] do
      Spec.Transformer.conform(spec, value)
    end
  end

  @spec conform!(Spec.Conformer.quoted, any) :: any
  defmacro conform!(spec, value) do
    quote do
      unquote(__MODULE__).conform(unquote(spec), unquote(value))
      |> case do
        {:ok, conformed} -> conformed
        {:error, mismatch = %Spec.Mismatch{}} -> raise mismatch
      end
    end
  end

  @spec valid?(Spec.Conformer.quoted, any) :: boolean
  defmacro valid?(spec, value) do
    quote do
      unquote(__MODULE__).conform(unquote(spec), unquote(value))
      |> Spec.Kernel.ok?
    end
  end

end
