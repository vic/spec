defmodule Spec.Key do

  @spec keys(Keyword.t | Enumerable.t, Keyword.t) :: Spec.Conformer.result
  defmacro keys(map_or_kw, opts) do
    Spec.Enumerable.keys_conform(map_or_kw, opts)
  end

end
