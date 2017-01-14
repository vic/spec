defmodule Spec.Def do

  @spec defspec(Macro.t, Keyword.t) :: Macro.t
  defmacro defspec(head, [do: conformer]) do
    unformer = quote do: fn x -> x end
    define(:def, head, conformer, unformer)
  end

  @spec defspec(Macro.t, Keyword.t) :: Macro.t
  defmacro defspecp(head, [do: conformer]) do
    unformer = quote do: fn x -> x end
    define(:defp, head, conformer, unformer)
  end

  defp define(def, head = {name, _, args}, conformer, unformer) do
    args = args || []
    conformer = Spec.Quoted.conformer(conformer)
    unformer = Spec.Quoted.conformer(unformer)

    value = Macro.var(:value, __MODULE__)
    value_args = [value] ++ args
    head_value = {name, [], value_args}

    any_head = args |> Enum.map(fn _ -> {:any, [], nil} end)
    any_args = value_args |> Enum.map(fn _ -> {:any, [], nil} end)

    predicate = quote do
      @spec unquote(name)(unquote_splicing(any_args)) :: boolean
      unquote(def)(unquote(:"#{name}?")(unquote_splicing(value_args))) do
        unquote(name)(unquote_splicing(value_args)) |> Spec.Kernel.ok?
      end
    end

    bang = quote do
      @spec unquote(name)(unquote_splicing(any_args)) :: any
      unquote(def)(unquote(:"#{name}!")(unquote_splicing(value_args))) do
        unquote(name)(unquote_splicing(value_args))
        |> case do
             {:ok, conformed} -> conformed
             {:error, mismatch = %Spec.Mismatch{}} -> raise mismatch
           end
      end
    end

    quote do
      @spec unquote(name)(unquote_splicing(any_head)) :: Spec.Transformer.t
      unquote(def)(unquote(head)) do
        %Spec.Transform{
          conformer: unquote(conformer),
          unformer: unquote(unformer)
        }
      end

      @spec unquote(name)(unquote_splicing(any_args)) :: Spec.Conformer.result
      unquote(def)(unquote(name)(unquote_splicing(value_args))) do
        Spec.Transformer.conform(unquote(name)(unquote_splicing(args)), unquote(value))
      end

      unquote_splicing(if :def == def, do: [predicate, bang], else: [])
    end
  end

end
