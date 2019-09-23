defprotocol Rubbergloves.Validation do
  alias Rubbergloves.Errors.Validation.ValidationError
  @fallback_to_any true

  @spec valid?(any) :: Boolean.t
  def valid?(validation)

  @spec errors(any) :: ValidationError | []
  def errors(validation)
end




defimpl Rubbergloves.Validation, for: Any do
  alias Rubbergloves.Errors.Validation.ValidationError

  def valid?(:ok), do: true
  def valid?(:invalid_type), do: false

  def errors(:ok), do: []
  def errors(:invalid_type), do: %ValidationError{ errors: [{:type, "Invalid type"}]}

end
