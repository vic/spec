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

  @spec quoted(spec :: t) :: any
  def quoted(spec)
end

defmodule Spec.Function do
  defstruct [:quoted, :conformer, :unformer]
end

defimpl Spec.Protocol, for: Spec.Function do
  def quoted(%{quoted: quoted}), do: quoted

  def conform(%{conformer: conformer, quoted: quoted}, value) do
    value
    |> conformer.()
    |> Spec.Conformer.result(value, quoted)
  end

  def unform(%{unformer: unformer, quoted: quoted}, value) do
    value
    |> unformer.()
    |> Spec.Conformer.result(value, quoted)
  end
end
