defmodule Rubbergloves.Annotations.ControllerAnnotations do
  alias Rubbergloves.Validation

  @moduledoc """
  A base controller to simplify input mapping, validation and authorization handlers.

  ## Example
  ```
  defmodule Example.AuthController do
    @handler_defaults [
      gloves: DefaultUserGloves,
      principle_resolver: &current_resource/1
    ]
    import Guardian.Plug

    use ExampleWeb, :controller
    use Rubbergloves.Annotations.ControllerAnnotations

    alias Example.Dto
    alias Example.Authorization.DefaultUserGloves
    alias Example.Accounts

    @bind request: Dto.UpdateCredentialsRequest
    @can_handle :update_user, :request, Example.DefaultUserGloves
    def update_user(conn, _, request: update_user_request) do
      with {:ok, user} <- Accounts.update_user(update_user_request) do
        json(conn, user)
      end
    end
  end
  ```
  """
  def get_or_error(options, key, message) do
    case Keyword.get(options, key) do
      nil -> {:error, message}
      item -> {:ok, item}
    end
  end

  defmacro __using__(_) do

    quote do
      use Rubbergloves.Annotatable, [:bind, :can_handle]
      import Rubbergloves.Annotations.ControllerAnnotations
      @handler_defaults []
      alias Rubbergloves.Errors.Controller.ValidationError

      @before_compile {unquote(__MODULE__), :__before_compile__}

      defp get_attribute(attributes, name) do
        Enum.find(attributes, fn %{annotation: annotation} -> annotation == name end)
      end
    end
  end

  defmacro make_controller_function(method) do
    quote bind_quoted: [method: method] do
      def unquote(:"#{method}")(conn, params) do
        attributes = Map.get(annotations(), unquote(method))

        with {:ok, mapping} <- get_attribute(attributes, :bind) |> get_mappings(params),
             :ok <- get_attribute(attributes, :can_handle) |> authorize(conn, params, mapping) do
          unquote(method)(conn, params, mapping)
        else
          err -> err
        end
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @annotations
      |> Enum.each(fn {method, _} -> make_controller_function(method) end)

      defp get_mappings(nil, _), do: {:ok, nil}

      defp get_mappings(bind, params) do
        module = bind.value
        structure = Rubbergloves.Mapper.map(struct(bind.value), params, module.mappings)
        result = module.validate(structure)

        if(Validation.valid?(result)) do
          {:ok, structure}
        else
          {:error, Validation.errors(result)}
        end
      end

      defp authorize(nil, _, _, _), do: :ok

      defp authorize(auth, conn, params, mapping) do
        options = auth.value ++ @handler_defaults

        with {:ok, action} <-
               get_or_error(
                 options,
                 :action,
                 ":action required for can_handle? attribute"
               ),
             {:ok, resource_loader} <-
               get_or_error(
                 options,
                 :principle_resolver,
                 ":resource_loader required for can_handle? attribute"
               ),
             {:ok, gloves} <-
               get_or_error(
                 options,
                 :gloves,
                 ":gloves required for can_handle? attribute"
               ) do
          gloves.handle(resource_loader.(conn), action, mapping)
        end
      end
    end
  end
end
