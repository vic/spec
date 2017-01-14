defmodule Spec.Def do

  @spec defspec(Macro.t) :: Macro.t
  defmacro defspec({name, _, [conformer]}) do
    unformer = quote do: fn x -> x end
    define(:def, name, conformer, unformer)
  end

  @spec defspec(Macro.t) :: Macro.t
  defmacro defspecp({name, _, [conformer]}) do
    unformer = quote do: fn x -> x end
    define(:defp, name, conformer, unformer)
  end

  defp define(def, name, conformer, unformer) do
    conformer = Spec.Quoted.conformer(conformer)
    unformer = Spec.Quoted.conformer(unformer)
    quote do

      @spec unquote(name)() :: Spec.Transformer.t
      unquote(def)(unquote(name)()) do
        %Spec.Transform{
          conformer: unquote(conformer),
          unformer: unquote(unformer)
        }
      end

      @spec unquote(name)(any) :: Spec.Conformer.result
      unquote(def)(unquote(name)(value)) do
        Spec.Transformer.conform(unquote(name)(), value)
      end

      @spec unquote(name)(any) :: boolean
      unquote(def)(unquote(:"#{name}?")(value)) do
        unquote(name)(value) |> Spec.Kernel.ok?
      end

      @spec unquote(name)(any) :: any
      unquote(def)(unquote(:"#{name}!")(value)) do
        unquote(name)(value)
        |> case do
             {:ok, conformed} -> conformed
             {:error, mismatch = %Spec.Mismatch{}} -> raise mismatch
           end
      end
    end
  end

end
