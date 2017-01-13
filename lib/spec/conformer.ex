defprotocol Spec.Conformer do

  alias Spec.Mismatch
  @type t :: any
  @type conformed :: {:ok, conformed :: any}
  @type mismatch  :: {:error, mismatch :: Mismatch.t}
  @type result :: conformed | mismatch
  @type quoted_expr :: any

  @doc """
  Return a quoted expression for this conformer.

  The expression should be partially applied, that is
  it should expect its first argument to be the value to conform.

  For example:

      is_integer()

  """
  @spec quoted(conformer :: t) :: quoted_expr
  def quoted(conformer)

  @spec conform(conformer :: t, value :: any) :: result
  def conform(conformer, value)
end
