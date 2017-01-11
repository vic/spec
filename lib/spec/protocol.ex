defprotocol Spec.Protocol do
  alias Spec.Mismatch

  @type t :: any
  @type conformed :: {:ok, conformed :: any}
  @type mismatch  :: {:error, mismatch :: Mismatch.t}
  @type result :: conformed | mismatch

  @spec conform(spec :: t, value :: any) :: result
  def conform(spec, value)

  @spec unform(spec :: t, value :: any) :: result
  def unform(spec, value)

  @spec exercise(spec :: t, options :: keyword()) :: result
  def exercise(spec, options)

  @spec quoted(spec :: t) :: any
  def quoted(spec)
end

defimpl Spec.Protocol, for: Function do
  def quoted(fun), do: fun.(:quoted)
  def conform(fun, value), do: fun.({:conform, value})
  def unform(fun, value), do: fun.({:unform, value})
  def exercise(fun, options), do: fun.({:excercise, options})
end
