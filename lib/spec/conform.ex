defprotocol Spec.Conform do
  alias Spec.Mismatch

  @type t :: any
  @type conformed :: {:ok, conformed :: any}
  @type mismatch  :: {:error, mismatch :: Mismatch.t}
  @type result :: conformed | mismatch

  @spec conform(conformer :: t, value :: any) :: result
  def conform(spec, value)
end

defimpl Spec.Conform, for: Function do
  def conform(fun, value), do: fun.({:conform, value})
end
