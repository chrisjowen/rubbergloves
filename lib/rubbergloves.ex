defmodule Rubbergloves do

  defmodule Error do
    defstruct [:reason, :args, children: []]
  end

  defmacro __using__(opts) do
    module = Keyword.get(opts, :wearer)

    quote do
      import Rubbergloves
      @before_compile Rubbergloves
      @module unquote(module)
      Module.register_attribute(__MODULE__, :phases, accumulate: true, persist: true)
      @phases :default
      @phase :default
    end
  end

  defmacro can_handle!(principle, action, conditions \\ nil) do
    quote do
      defp handle_check(@phase, @module, unquote(principle), unquote(action), unquote(conditions)) do
        :ok
      end
    end
  end

  defmacro can_handle?(principle, action, conditions \\ nil, do: block) do
    quote do
      defp handle_check(
             @phase,
             @module,
             unquote(principle) = principle,
             unquote(action) = action,
             unquote(conditions) = conditions
           ) do

        process_check(unquote(block), [@phase, @module, principle, action, conditions])
      end
    end
  end

  defmacro phase(name, do: block) do
    quote do
      @phase unquote(name)
      @phases unquote(name)
      unquote(block)
      @phase :default
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp handle_check(phase, type, principle, action, conditions),
        do: process_check({:error, :no_handler_found}, [@phase, @module, principle, action, conditions])

      def handle(principle, action, conditions \\ nil, phases \\ @phases)
          when is_map(principle) do
        struct = Map.get(principle, :__struct__)

        phases
        |> Enum.reverse()
        |> Enum.reduce(nil, fn phase, message ->
          case message do
            :ok -> :ok
            %Rubbergloves.Error{} = error ->
              merge_errors(error, handle_check(phase, struct, principle, action, conditions))
            nil ->
             handle_check(phase, struct, principle, action, conditions)
          end
        end)
      end

      defp merge_errors(_, :ok), do: :ok
      # defp merge_errors({:error, errors}, {:error, next_error}) when is_list(errors), do: {:error, errors ++ [next_error]}
      defp merge_errors(%Rubbergloves.Error{} = error, %Rubbergloves.Error{}=next_error) do
        Map.merge(error, %{reason: next_error.reason, children: error.children ++ [next_error]})
      end

      defp process_check(:ok, _), do: :ok
      defp process_check(true, _), do: :ok
      defp process_check({:error, reason}, args), do: %Rubbergloves.Error{args:  args , reason: reason}
      defp process_check(_, args), do: %Rubbergloves.Error{args: args, reason: :unknown}

    end
  end
end
