defmodule Rubbergloves.Util.CamelCaseKeyResolver do
  def resolve(key) do
    [h | t] =
      key
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.split("", trim: true)

    String.downcase(h) <> Enum.join(t)
  end
end
