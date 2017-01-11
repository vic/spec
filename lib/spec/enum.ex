defmodule Spec.Enum do
  @moduledoc false

  alias Spec.Mismatch
  alias Spec.Conformer

  def tuple(tuple, _) when not is_tuple(tuple) do
    Mismatch.error(
      reason: "is not a tuple",
      subject: tuple)
  end

  def tuple(tuple, conformers) do
    result = tuple |> Tuple.to_list |> list(conformers)
    case result do
      {:ok, conformed} -> {:ok, List.to_tuple(conformed)}
      {:error, mismatch = %Mismatch{}} ->
        {:error, %Mismatch{ mismatch | subject: tuple}}
    end
  end

  def list(list, conformers) when length(list) != length(conformers) do
    Mismatch.error(
      reason: "does not have length #{length(conformers)}",
      subject: list)
  end

  def list(enum, conformers) do
    items(enum, conformers)
  end

  def items(enum, conformers) do
    Stream.zip([enum, conformers])
    |> Stream.with_index
    |> Enum.flat_map_reduce(nil, &item_conform/2)
    |> case do
      {conforms, nil} -> {:ok, conforms}
      {_, {index, failure}} ->
        Mismatch.error_in(failure, subject: enum, at: index)
    end
  end

  defp item_conform({{item, conformer}, index}, nil) do
    case Conformer.pipe(item, conformer) do
      {:ok, conformed} -> {[conformed], nil}
      {:error, failure} -> {:halt, {index, failure}}
    end
  end

  def keyword(kw, kw_conforms, into) do
    kw
    |> Enum.flat_map_reduce({kw_conforms, _failures = []}, &kw_map_reduce/2)
    |> case do
      {conforms, {_, _failures = []}} ->
        {:ok, Enum.into(conforms, into)}
      {_, {_, failures}} ->
        Mismatch.error(subject: kw, reason: failures)
    end
  end

  defp kw_map_reduce({k, v}, {kvc, failures}) do
    conform_value = fn ck, vc ->
      case Conformer.pipe(v, vc) do
        {:ok, cv} ->
          {:ok, {ck, cv}}
        {:error, value_mismatch} ->
          {:error, Map.put(value_mismatch, :at, k)}
      end
    end

    continue = fn
      {:ok, conformed} -> {[conformed], {kvc, failures}}
      {:error, failure} -> {[], {kvc, [failure | failures]}}
      nil -> {[], {kvc, failures}}
    end

    kvc
    |> Enum.find_value(fn
      {kc, vc} ->
        case Conformer.pipe(k, kc) do
          {:error, _failure} -> nil
          {:ok, ck} -> conform_value.(ck, vc)
        end
    end)
    |> continue.()
  end

  def keys(map = %x{}, required, optional) do
    kv = keys(map, %{req: required, opt: optional,
                     mod: Map, into: Keyword.new})
    struct(x, kv)
  end

  def keys(map, required, optional) when is_map(map) do
    keys(map, %{req: required, opt: optional,
                mod: Map, into: Map.new})
  end

  def keys(kw, required, optional) do
    keys(kw, %{req: required, opt: optional,
               mod: Keyword, into: Keyword.new})
  end

  def keys(enum, %{req: req, opt: opt, mod: mod, into: into}) do
    {got_req, miss_req} = keys_from(enum, req)
    case miss_req do
      [] ->
        {got_opt, _miss_opt} = keys_from(enum, opt)
        {:ok, mod.take(enum, got_req ++ got_opt) |> Enum.into(into)}
      err = %Mismatch{} -> {:error, err}
    end
  end

  defp keys_from(enum, keys) do
    Enum.flat_map_reduce(keys, _missed = [], fn
      key, missed ->
        Conformer.pipe(enum, key)
        |> case do
            {:ok, founds} -> {founds, missed}
            {:error, miss} -> {[], missed ++ miss}
           end
    end)
  end

  def has_key?(enum, {:and, ak, bk}) do
    case Conformer.pipe(enum, ak) do
      {:ok, akeys} ->
        case Conformer.pipe(enum, bk) do
          {:ok, bkeys} -> {:ok, akeys ++ bkeys}
          error -> error
        end
      error -> error
    end
  end

  def has_key?(enum, {:or, ak, bk}) do
    case Conformer.pipe(enum, ak) do
      {:ok, akeys} -> {:ok, akeys}
      {:error, %{expr: amissed}} ->
        case Conformer.pipe(enum, bk) do
          {:ok, bkeys} -> {:ok, bkeys}
          {:error, %{expr: bmissed}} ->
            Mismatch.error(subject: enum,
              reason: "does not have any of keys",
              expr: amissed ++ bmissed)
        end
    end
  end

  def has_key?(list, key) when is_list(list) and is_atom(key) do
    if Keyword.has_key?(list, key) do
      {:ok, [key]}
    else
      Mismatch.error(subject: list,
        reason: "does not have key", expr: [key])
    end
  end

  def has_key?(map, key) when is_map(map) and is_atom(key) do
    if Map.has_key?(map, key) do
      {:ok, [key]}
    else
      Mismatch.error(subject: map,
        reason: "does not have key", expr: [key])
    end
  end

  def repeat(tuple, conformer, opts) when is_tuple(tuple) do
    repeat(tuple |> Tuple.to_list, conformer, opts)
  end

  def repeat(list, _conformer, %{max: max, fail_fast: true}) when length(list) > max do
    Mismatch.error(subject: list,
      reason: "does not have max length of #{max}")
  end

  def repeat(list, _conformer, %{min: min, fail_fast: true}) when length(list) < min do
    Mismatch.error(subject: list,
      reason: "does not have min length of #{min}")
  end

  def repeat(list, conformer, %{min: min, max: max, fail_fast: fail_fast}) do
    list
    |> Stream.with_index(1)
    |> Enum.flat_map_reduce([], fn
      {_, size}, _ when size > max ->
        {_, failure} = Mismatch.error(subject: list,
          reason: "does not have max length of #{max}")
        {:halt, failure}
      {item, _}, failures ->
        case Conformer.pipe(item, conformer) do
          {:ok, conformed} -> {[conformed], []}
          {:error, failure} when fail_fast == true -> {:halt, failure}
          {:error, failure} -> {[], [failure | failures]}
        end
    end)
    |> case do
      {conformed, []} when length(conformed) < min ->
          Mismatch.error(subject: list,
            reason: "does not have min length of #{min}")
      {conformed, []} -> {:ok, conformed}
      {_, failures} when is_list(failures) ->
          Mismatch.error(subject: list,
            reason: {"items do not conform", Enum.reverse(failures)})
      {_, failure} -> {:error, failure}
    end
  end

end
