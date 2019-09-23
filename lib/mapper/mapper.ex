defmodule Rubbergloves.Mapper do
  @moduledoc"""
  The core module to convert your input into a struct using the previously defined stucture mappings

  ### Usage
  ```
  Rubbergloves.Mapper.map(LoginRequest, params)
  """

  defmodule Override do
    defstruct [key: :default, value: :default]
  end

  defmodule Options do
    defstruct [keys: &Rubbergloves.Mapper.IdentityKeyResolver.resolve/1, overrides: %{}]
  end

  def map(struct, map, opts \\  %Options{})
  def map(module, map, nil), do: map(struct(module), map, module.mappings)
  def map(struct, map, opts) do
    Enum.reduce(keys(struct), struct, fn key, struct ->
      case fetch(map, key, opts) do
        {:ok, v} -> %{struct | key => value(key, v, opts)}
        :error ->  %{struct | key => default(key, Map.get(struct, key), opts)}
      end
    end)
  end

  # Fetch eith uses the hard coded key or the function provided
  defp fetch(map, key, %Options{keys: key_fun}=options) when is_function(key_fun), do: fetch(map, key, key_fun, options)
  defp fetch(map, key, fun, %Options{overrides: overrides}) when is_function(fun) do
    case Map.get(overrides, key) do
      nil -> Map.fetch(map, fun.(key))
      %Override{key: key_fn} when is_function(key_fn) -> Map.fetch(map, key_fn.(key))
      %Override{key: new_key} -> Map.fetch(map, new_key)
    end
  end

  # Value from map with no further mapping function
  defp value(key, value, %Options{overrides: overrides}) do
    case Map.get(overrides, key) do
      nil -> value
      %Override{value: :default} -> value
      %Override{value: value_fn} when is_function(value_fn) -> value_fn.(value)
      _ -> raise "Expected override for value of #{key} to be a function"
    end
  end

  # Default from struct defenition
  defp default(_, default_val, _), do: default_val

  defp keys(map) do
      Map.to_list(map)
        |> Enum.map(fn {key, _} -> key end)
        |> Enum.filter(fn(key) -> Atom.to_string(key) != "__struct__" end)
  end
end
