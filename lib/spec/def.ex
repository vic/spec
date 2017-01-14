defmodule Spec.Def do

  @spec defspec(Macro.t) :: Macro.t
  defmacro defspec({name, _, [quoted_expr]}) do
    conformer = Spec.Quoted.conformer(quoted_expr)
    unformer = Spec.Quoted.conformer(quote do: fn x -> x end)
    quote do

      @spec unquote(name)() :: Spec.Transformer.t
      def unquote(name)() do
        %Spec.Transform{
          conformer: unquote(conformer),
          unformer: unquote(unformer)
        }
      end

      @spec unquote(name)(any) :: Spec.Conformer.result
      def unquote(name)(value) do
        Spec.Transformer.conform(unquote(name)(), value)
      end

      @spec unquote(name)(any) :: boolean
      def unquote(:"#{name}?")(value) do
        unquote(name)(value) |> Spec.Kernel.ok?
      end

      @spec unquote(name)(any) :: any
      def unquote(:"#{name}!")(value) do
        unquote(name)(value)
        |> case do
          {:ok, conformed} -> conformed
          {:error, mismatch = %Spec.Mismatch{}} -> raise mismatch
        end
      end
    end
  end

end
