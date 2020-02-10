

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
  defmodule Match do
    defstruct [:phase, :reason,  :success?]
  end

  defmodule MatchInfo do
    defstruct [:wearer, :conditions, :action, :handler, matches: []]
  end

  alias Rubbergloves.Handler.Match
  alias Rubbergloves.Handler.MatchInfo

  defmacro __using__(opts) do
    module = Keyword.get(opts, :wearer)
    quote do
      import Rubbergloves.Handler
      alias Rubbergloves.Handler.Match
      alias Rubbergloves.Handler.MatchInfo
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
      defp handle_check(@phase, @module, unquote(principle) = principle, unquote(action) = action, unquote(conditions) = conditions) do
        process_check(:ok, [@phase, @module, principle, action, conditions])
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
  defmacro can_handle?(principle, action, conditions \\ nil,  do: block)  do
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

  defmacro phase(name, [handle_by: handler]) do
    quote do
      @phase unquote(name)
      @phases unquote(name)
      defp handle_check(@phase, @module, principle, action, conditions) do
        {_, result} = unquote(handler).handle(principle, action, conditions)
        result
      end
      @phase :default
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
        do: process_check({:error, :no_matching_handler}, [@phase, @module, principle, action, conditions])

      def handle(principle, action, conditions \\ nil, phases \\ @phases) when is_map(principle) do
        struct = Map.get(principle, :__struct__)
        matches = phases
        |> Enum.reverse()
        |> Enum.reduce([], fn phase, acum  ->
            if(is_success(acum)) do
              acum
            else
              [handle_check(phase, struct, principle, action, conditions)] ++ acum
            end
        end)

        info = %MatchInfo{wearer: principle, matches: matches, handler: __MODULE__, action: action, conditions: conditions,}
        if(is_success(info)) do
          {:ok, info}
        else
          {:error, info}
        end
      end

      def is_success(%Match{success?: success}), do: success
      def is_success(matches) when is_list(matches), do: Enum.any?(matches, &is_success/1)
      def is_success(%MatchInfo{matches: matches}), do: is_success(matches)
      def is_success(_), do: false


      defp merge_errors(_, :ok), do: :ok
      defp merge_errors(error, failed_match) do
        Map.merge(error, :matches, Map.get(error, :matches) ++ failed_match)
      end

      defp process_check(:ok, meta), do: success(meta)
      defp process_check(true, meta), do: success(meta)
      defp process_check(false, meta), do: process_check({:error, :match_failed}, meta)
      defp process_check({:error, reason}, [phase, handler, _principle, action, conditions]), do: %Match{phase: phase, reason: reason, success?: false}
      defp success([phase, handler, _principle, action, conditions]), do: %Match{phase: phase,   success?: true}
    end
  end
end
