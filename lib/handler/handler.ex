

defmodule Rubbergloves.Handler do
  @moduledoc"""
  A series of macros to determine how to authorize a specific action for a principle.

  # Usage

  ## 1. Define what your rubber gloves can handle
  ```
  defmodule MyApp.Gloves do
    use Rubbergloves.Handler, wearer: MyApp.User

    # wizzards can handle any poison
    can_handle!(%MyApp.User{type: "wizzard"}, :pickup_poison, %{poison: _any})

    # apprentice need to be qualified
    can_handle?(%MyApp.User{type: "apprentice"} = apprentice, :pickup_poison, %{poison: poison}) do
      Apprentice.is_qualified_to_handle?(apprentice, poison)
    end

    # Can use multipule phase checks, so if previosu phase fails we can fallback to other checks
    phase :secondary_check do
      can_handle?(%MyApp.User{race: "human"} = apprentice, :pickup_poison, %{poison: poison}) do
        ImmunityDatabase.is_immune_to(apprentice, poison)
      end
    end
  end
  ```
  ## 2. Check if wearer can handle
  ```
  defmodule MyApp.SomeController do
    def index(conn, params) do
      user = get_principle_somehow()
      with :ok <- MyApp.Gloves.handle(user, :read_secret_recipe, params. [:default, :secondary_check]) do
        fetch_recipe(params["recipe_id"])
      end
    end
  end
  ```

  ## 3. Providing Insights
  ```
  defmodule MyApp.Gloves do
    use Rubbergloves, wearer: MyApp.User

    # Return boolean to provide no isights
    can_handle?(user, :read_secret_recipe) do
      false
    end

     # Optionally return {:error, reason} tuple to give better feedback
    can_handle?(user, :read_secret_recipe) do
      {:error, :novice_warlock}
    end

  end
  ```
  """
  defmacro __using__(opts) do
    module = Keyword.get(opts, :wearer)
    quote do
      import Rubbergloves.Handler

      @before_compile Rubbergloves.Handler
      @module unquote(module)
      Module.register_attribute(__MODULE__, :phases, accumulate: true, persist: true)
      @phases :default
      @phase :default
    end
  end

  @doc"""
  Macro to confirm that the priniciple can handle a given action with speciic conditions

  i.e. allow everyone to do anything
  > can_handle!(_any_principle, _any_action, _any_conditions)
  """
  defmacro can_handle!(principle, action, conditions \\ nil) do
    quote do
      defp handle_check(@phase, @module, unquote(principle), unquote(action), unquote(conditions)) do
        :ok
      end
    end
  end

  @doc"""
  Macro to check if the priniciple can handle a given action with speciic conditions.

  i.e. allow everyone to do anything
  > can_handle?(_any_principle, :action, _any_conditions) do
  >   true
  > end
  """
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
        do: process_check({:error, :missing_handler}, [@phase, @module, principle, action, conditions])

      def handle(principle, action, conditions \\ nil, phases \\ @phases)
          when is_map(principle) do
        struct = Map.get(principle, :__struct__)
        phases
        |> Enum.reverse()
        |> Enum.reduce(nil, fn phase, message ->
          case message do
            :ok -> :ok
            %Rubbergloves.Errors.HandleError{} = error ->
              merge_errors(error, handle_check(phase, struct, principle, action, conditions))
            nil ->
             handle_check(phase, struct, principle, action, conditions)
          end
        end)
      end

      defp merge_errors(_, :ok), do: :ok
      defp merge_errors(%Rubbergloves.Errors.HandleError{} = error, %Rubbergloves.Errors.HandleError{}=next_error) do
        Map.merge(error, %{reason: next_error.reason, children: error.children ++ [next_error]})
      end

      defp process_check(:ok, _), do: :ok
      defp process_check(true, _), do: :ok
      defp process_check({:error, reason}, args), do: %Rubbergloves.Errors.HandleError{args: args , reason: reason}
      defp process_check(_, args), do: %Rubbergloves.Errors.HandleError{args: args, reason: :unknown}
    end
  end
end
