defmodule Spec.Def do

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2, defp: 2]
      import Spec.Def, only: [def: 2, defp: 2]
    end
  end

  alias __MODULE__.Instrumented

  defmacro unquote(:def)(call, expr) do
    Instrumented.define(:def, call, expr)
  end

  defmacro unquote(:defp)(call, expr) do
    Instrumented.define(:defp, call, expr)
  end


  defmodule Instrumented do
    @moduledoc false # internal API
    @at_kernel [context: Elixir, import: Kernel]

    def define(def, head, options) do
      quote do
        case @fn_spec do
          nil ->
            Kernel.unquote(def)(unquote_splicing([head, options]))
          ref when is_function(ref, 1) ->
            require Instrumented
            Instrumented.define_instrumented(@fn_spec,
              unquote_splicing([def, head, options]))
            Module.delete_attribute(__MODULE__, :fn_spec)
        end
      end
    end

    defmacro define_instrumented(fn_spec, def, {name, _, args}, options) do
      {iargs, {_, vars}} = args |> Enum.flat_map_reduce({0, []}, fn
        arg = {name, _, nil}, {idx, vars} when is_atom(name) ->
        {[arg], {idx + 1, [arg | vars]}}
        arg, {idx, vars} ->
          var = Macro.var(:"arg#{idx}", __MODULE__)
        {[quote do: unquote(var) = unquote(arg)], {idx + 1, [var | vars]}}
      end)
      vars = Enum.reverse(vars)
      unname = :"__unconformed__#{name}"
      unhead = {unname, [], args}
      unref = {:&, [], [{:/, @at_kernel, [{unname, [], nil}, length(args)]}]}
      ihead = {name, [], iargs}
      ibody = quote do
        unquote(fn_spec).({unquote(unref), unquote(vars)})
      end
      quote do
        Kernel.defp(unquote(unhead), unquote(options))
        Kernel.unquote(def)(unquote(ihead), [do: unquote(ibody)])
      end
    end

  end
end
