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

  @type conformer(Spec.Conformer.fun, Spec.Conformer.fun) :: Spec.Transformer.t
  def conformer(conformer, unformer \\ fn x -> x end) do
    fn
      {:conform, value} ->
        conformer.(value) |> Spec.Quoted.result(value, inspect(conformer))
      {:unform, value} ->
        unformer.(value) |> Spec.Quoted.result(value, inspect(unformer))
    end
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
      |> Spec.Conform.ok?
    end
  end
end
