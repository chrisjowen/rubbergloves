defmodule Rubbergloves.Mapper.CamelCaseKeyResolver do
  def resolve(key) do
    [h | t] =
      key
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.split("", trim: true)

    String.downcase(h) <> Enum.join(t)
  end
end


defmodule Rubbergloves.Mapper.IdentityKeyResolver do
  def resolve(key) when is_atom(key), do: Atom.to_string(key)
  def resolve(key), do: key
end

