defmodule Rubbergloves.EctoSerializer do
  @moduledoc """
  Utility to serialize ecto structs to maps
  """

  @exceptions [NaiveDateTime, DateTime]
  @bloat [:__meta__, :__struct__, :__cardinality__, :__field__, :__owner__]

  def serialize(schema, modules) when is_map(schema) do
    additional =
      cond do
        Map.has_key?(schema, :__struct__) ->
          {_, additional} =
            Enum.find(modules, {:none, []}, fn {module, _} -> module == schema.__struct__ end)

          additional

        true ->
          []
      end

    keys = (Map.keys(schema) -- @bloat) -- additional

    Map.take(schema, keys)
    |> Enum.map(&serialize(&1, modules))
    |> Enum.into(%{})
  end

  def serialize({key, %{__struct__: struct} = val}, _) when struct in @exceptions, do: {key, val}
  def serialize(list, modules) when is_list(list), do: Enum.map(list, &serialize(&1, modules))

  def serialize({key, val}, modules) when is_map(val) or is_list(val),
    do: {key, serialize(val, modules)}

  def serialize(data, _), do: data
end
