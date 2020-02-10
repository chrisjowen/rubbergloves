defmodule Rubbergloves.Mapper.CamelCaseKeyResolver do
  def resolve(key, _map) do
    [h | t] =
      key
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.split("", trim: true)

    String.downcase(h) <> Enum.join(t)
  end
end

defmodule Rubbergloves.Mapper.StringKeyResolver do
  def resolve(key, _map),  do: Atom.to_string(key)
end

defmodule Rubbergloves.Mapper.AtomKeyResolver do
  def resolve(key, _map), do: key
end

defmodule Rubbergloves.Mapper.DynamicKeyResolver do
  alias Rubbergloves.Mapper.StringKeyResolver

  def resolve(key, map) do
    cond do
      Map.has_key?(map, key) -> key
      true -> StringKeyResolver.resolve(key, map)
    end
  end

end

