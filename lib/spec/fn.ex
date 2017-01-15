defmodule Spec.Fn do
  defmacro __using__ do
    quote do
      import Spec.Fn
      import Kernel, except: [def: 2]
      import Spec.Fn.Def, only: [def: 2]
    end
  end

  alias Spec.{Quoted, Fn.Instrumented}

  defmacro fspec(fn_and_args, opts) do
    defaults = %{ret: {:_, [], nil}, fn: {:_, [], nil}}
    opts = Map.merge(defaults, Map.new(opts))
    args = opts
      |> Map.get_lazy(:args, fn -> raise "Missing :args spec" end)
      |> Quoted.conformer()
    ret = opts[:ret] |> Quoted.conformer()
    fcon = opts[:fn] |> Quoted.conformer()
    opts = Map.merge(opts, %{args: args, ret: ret, fn: fcon}) |> Enum.into([])
    quote do
      fn {fun, args} ->
        opts = unquote(opts)
        with \
        {:ok, conformed_args} <- Quoted.pipe(args, opts[:args]),
               ret = apply(fun, case opts[:apply] do
                                  :conformed -> conformed_args |> Enum.to_list
                                  _ -> args
                                end),
             {:ok, conformed_ret} <- Quoted.pipe(ret, opts[:ret]),
             {:ok, conformed_fn} <- [args: conformed_args, ret: conformed_ret]
             |> Quoted.pipe(opts[:fn]) do
          {:ok, case opts[:return] do
                  :conformed -> conformed_ret
                  :conformed_fn -> conformed_fn
                  _ -> ret
                end}
        end
      end.(unquote(fn_and_args))
    end
  end

  defmacro defconform(head, options) do
    Instrumented.define(:def, head, options)
  end

  defmodule Def do
    defmacro unquote(:def)(call, expr) do
      Instrumented.define(:def, call, expr)
    end
  end

  defmodule Instrumented do
    @moduledoc false
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
