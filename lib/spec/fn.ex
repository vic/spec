defmodule Spec.Fn do
  alias Spec.{Quoted, Def.Instrumented}

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
end
