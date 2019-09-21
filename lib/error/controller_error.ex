defmodule Rubbergloves.Errors.Controller do
  defmodule ValidationError do
    defstruct [:errors]

    def to_json(error = %__MODULE__{}) do
      Enum.map(error.errors, &errors_to_json/1) |> Enum.into(%{})
    end

    defp errors_to_json(pass, prefix \\ "")
    defp errors_to_json({key, {message, _}}, prefix) do
      {"#{prefix}#{key}", message}
    end

    defp errors_to_json({key, [next]}, prefix) do
      errors_to_json(next, "#{prefix}#{key}.")
    end

  end
end
