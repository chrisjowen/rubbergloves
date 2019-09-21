defmodule Rubbergloves.Controller do
  alias Rubbergloves.Errors.Controller.ValidationError

  def get_or_error(options, key, message) do
    case Keyword.get(options, key) do
      nil -> {:error, message}
      item -> {:ok, item}
    end
  end

  defmacro __using__(_) do
    quote do
      use Rubbergloves.Annotatable, [:bind, :can_handle]
      import Rubbergloves.Controller
      @handler_defaults []
      alias Rubbergloves.Errors.Controller.ValidationError

      @before_compile {unquote(__MODULE__), :__before_compile__}

      defp get_annotation(annotations, name) do
        Enum.find(annotations, fn %{annotation: annotation} -> annotation == name end)
      end
    end
  end

  defmacro make_controller_function(method, annotations) do
    quote bind_quoted: [method: method, annotations: annotations] do
      def unquote(:"#{method}")(conn, params) do
        annotations = Map.get(annotations, unquote(method))
        with {:ok, mapping} <- get_annotation(annotations, :bind) |> get_mappings(params),
             :ok <- get_annotation(annotations, :can_handle) |> authorize(conn, params, mapping) do
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
      |> Enum.each(fn {method, annotations} -> make_controller_function(method, annotations) end)


      defp get_mappings(nil, _), do: {:ok, nil}

      defp get_mappings(bind, params) do
        module = bind.value
        structure = Rubbergloves.Mapper.map(struct(bind.value), params, module.mappings)
        validation = module.validate(structure)

        if(validation.valid?) do
          {:ok, structure}
        else
          {:error, %ValidationError{errors: validation.errors}}
        end
      end

      defp authorize(nil), do: :ok
      defp authorize(auth, conn, params, mapping) do
        action = auth.value
        action = auth.value
        options = auth.value ++ @handler_defaults

        with {:ok, action} <- Rubbergloves.Controller.get_or_error(options, :action, ":action required for can_handle? attribute"),
              {:ok, resource_loader} <- Rubbergloves.Controller.get_or_error(options, :principle_resolver, ":resource_loader required for can_handle? attribute"),
              {:ok, gloves} <- Rubbergloves.Controller.get_or_error(options, :gloves, ":gloves required for can_handle? attribute") do
              gloves.handle(resource_loader.(conn), action, mapping)
        end
      end
    end
  end
end
