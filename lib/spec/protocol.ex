defprotocol Spec.Protocol do
  @spec conform(spec :: any, value :: any) :: Spec.Conformer.result
  def conform(spec, value)

  @spec unform(spec :: any, value :: any) :: Spec.Conformer.result
  def unform(spec, value)
end
