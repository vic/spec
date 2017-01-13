defmodule Spec.Mismatch do
  defexception [:subject, :reason, :expr, :at, :in]

  @type t :: %__MODULE__{}

  @spec error(opts :: keyword()) :: {:error, mismatch :: t}
  def error(opts) do
    {:error, struct(__MODULE__, opts)}
  end

  def error_in(inner = %__MODULE__{}, opts) do
    parent = struct(__MODULE__, Keyword.drop(opts, [:at]))
    mismatch = %__MODULE__{inner | at: opts[:at], in: parent}
    {:error, mismatch}
  end

  def message(mismatch = %__MODULE__{}) do
    to_string(mismatch)
  end

end

defimpl String.Chars, for: Spec.Mismatch do

  defp indent(string) do
    String.replace(string, ~r/^/, "  ")
  end

  defp next_indent(str) do
    cond do
      String.match?(str, ~r/\n/) -> indent(str)
      :inline -> str
    end
  end

  defp rstrip(string) do
    String.replace_suffix(string, "\n", "")
  end

  defp code(str) do
    cond do
      String.match?(str, ~r/\n/) ->
        """
        ```elixir
        #{indent(str)}
        ```
        """ |> rstrip
      :inline -> "`#{str}`"
    end
  end

  defp n_failures([_]), do: "one failure"
  defp n_failures(x), do: "#{length(x)} failures"

  defp format(%{subject: subject, reason: reasons}) when is_list(reasons) do
    """
    Inside #{code(inspect(subject))}, #{n_failures(reasons)}:

    #{format_reasons(reasons)}
    """ |> rstrip
  end

  defp format(mismatch = %{at: nil}) do
    """
    #{subject_reason(mismatch)}
    """ |> rstrip
  end

  defp format(mismatch = %{at: at, in: parent}) when not is_nil(parent) do
    """
    #{subject_reason(mismatch)}

    at #{code(inspect(at))} in #{next_indent(format(parent))}
    """ |> rstrip
  end

  defp format_reasons(reasons) do
    reasons
    |> Stream.with_index
    |> Enum.map(fn
      {reason, index} ->
      """
      (failure #{index+1})#{reason.at && " at " <> code(inspect(reason.at))}

      #{subject_reason(reason) |> indent}

      """
    end)
    |> Enum.join
    |> rstrip |> rstrip
  end

  defp subject_reason(%{subject: subject, reason: reason, expr: expr}) do
    [
      code(inspect(subject)),
      case reason do
        nil -> ""
        {reason, _} -> [" ", reason]
        reason -> [" ", reason]
      end,
      expr && [" ", code(Macro.to_string(expr))] || "",
      case reason do
        {_, reasons} -> ["\n\n", format_reasons(reasons)]
        _ -> ""
      end
    ]
    |> Kernel.to_string()
  end

  def to_string(mismatch = %Spec.Mismatch{}) do
    format(mismatch)
  end
end

