defmodule Spec.Define do

  defmacro defspec({name, _, [quoted_expr]}) do
    conformer = Spec.Quoted.conformer(quoted_expr)
    unformer = Spec.Quoted.conformer(quote do: fn x -> x end)
    quote do
      def unquote(name)() do
        %Spec.Transform{
          conformer: unquote(conformer),
          unformer: unquote(unformer)
        }
      end

      def unquote(name)(value) do
        Spec.Protocol.conform(unquote(name)(), value)
      end

      def unquote(:"#{name}?")(value) do
        unquote(name)(value) |> Spec.Conform.ok?
      end

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
