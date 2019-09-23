defmodule Rubbergloves.EctoEncoder do
  @moduledoc"""
  Utility to encode ecto structs
  """

  defmodule CamelCaseEncoder do
    def encode({key, val}), do: {to_camel_case(key), encode(val)}
    def encode(%{__struct__: _} = struct), do: struct
    def encode(map) when is_map(map), do: Enum.map(map, &encode/1) |> Enum.into(%{})
    def encode(list) when is_list(list), do: Enum.map(list, &encode/1)
    def encode(val), do: val

    defp to_camel_case(key) when is_atom(key) do
      [h | t] =
        key
        |> Atom.to_string()
        |> Macro.camelize()
        |> String.split("", trim: true)

      (String.downcase(h) <> Enum.join(t))
      |> String.to_atom()
    end
  end

  defmacro encode(modules) do
    quote do
      Enum.map(unquote(modules), fn {module, strip} ->
        defimpl Jason.Encoder, for: module do
          def encode(schema, opts) do
            stripped = Rubbergloves.EctoSerializer.serialize(schema, unquote(modules))

            stripped
            |> Map.take(Map.keys(stripped))
            |> CamelCaseEncoder.encode()
            |> Jason.Encode.map(opts)
          end
        end
      end)
    end
  end
end
