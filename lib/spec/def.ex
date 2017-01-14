defmodule Spec.Def do

  @spec defspec(Macro.t, Keyword.t) :: Macro.t
  defmacro defspec(head, options) do
    define(:def, head, options)
  end

  @spec defspec(Macro.t, Keyword.t) :: Macro.t
  defmacro defspecp(head, options) do
    define(:defp, head, options)
  end

  defp define(def, head = {name, _, args}, options) do
    conformer = options
      |> Keyword.get_lazy(:do, fn -> raise "Expected `do` for spec." end)
      |> Spec.Quoted.conformer

    unformer = options
      |> Keyword.get(:undo, quote do: fn x -> x end)
      |> Spec.Quoted.conformer

    include = options
      |> Keyword.get_lazy(:include, fn ->
        if :def == def, do: [:pred, :bang], else: []
      end)

    args = args || []
    anys = Enum.map(args, fn _ -> {:any, [], __MODULE__} end)
    vary = Enum.with_index(args) |> Enum.map(fn {_, i} -> {:"var#{i}", [], __MODULE__} end)

    predicate = quote do
      @spec unquote(name)(value :: any, unquote_splicing(anys)) :: boolean
      unquote(def)(unquote(:"#{name}?")(value, unquote_splicing(vary))) do
        value
        |> unquote(name)(unquote_splicing(vary))
        |> Spec.Kernel.ok?
      end
    end

    bang = quote do
      @spec unquote(name)(value :: any, unquote_splicing(anys)) :: any
      unquote(def)(unquote(:"#{name}!")(value, unquote_splicing(vary))) do
        value
        |> unquote(name)(unquote_splicing(vary))
        |> case do
             {:ok, conformed} -> conformed
             {:error, mismatch = %Spec.Mismatch{}} -> raise mismatch
           end
      end
    end

    versions = [pred: predicate, bang: bang] |> Keyword.take(include) |> Keyword.values

    quote do
      @spec unquote(name)(unquote_splicing(anys)) :: Spec.Transformer.t
      unquote(def)(unquote(head)) do
        %Spec.Transform{
          conformer: unquote(conformer),
          unformer: unquote(unformer)
        }
      end

      @spec unquote(name)(value :: any, unquote_splicing(anys)) :: Spec.Conformer.result
      unquote(def)(unquote(name)(value, unquote_splicing(vary))) do
        Spec.Transformer.conform(unquote(name)(unquote_splicing(vary)), value)
      end

      unquote_splicing(versions)
    end
  end

end
