defprotocol Spec.Protocol do
  @spec conform(spec :: any, value :: any) :: Spec.Conformer.result
  def conform(spec, value)

  @spec unform(spec :: any, value :: any) :: Spec.Conformer.result
  def unform(spec, value)
end

defimpl Spec.Protocol, for: Function do
  def conform(func, value) do
    func.({:conform, value})
  end

  def unform(func, value) do
    func.({:unform, value})
  end
end
