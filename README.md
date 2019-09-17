# Rubbergloves

Simple DSL to ensure only authorized users can handle your elixir toxins. 

# Usage


1. Define your rubber gloves capabilities

```
defmodule MyApp.Gloves do
  use Rubbergloves, wearer: MyApp.User

  can_handle!(%MyApp.User{name: "fred"}, _action, %{precondition: true})
  can_handle!(%MyApp.User{name: "chris"}, :poision)

end
```

2. Use the gloves when handling toxins


```
defmodule MyApp.SomeController do
  
  def index(conn, params) do
    user = get_user_somehow()

    with :ok <- MyApp.Gloves.handle(user, :read_secret_recipe, params) do
      fetch_recipe(params["recipe_id"])
    end

  end

end

```
# Further Usage
## Multi step checks 

```
defmodule MyApp.Gloves do
  use Rubbergloves, wearer: MyApp.User

  # First we check here
  phase :explicit_checks do
    can_handle!(%MyApp.User{ role: "ADMIN"}, :read_secret_recipe)
  end
 
  # If cannot handle then we check the database
  phase :database_check do
    can_handle?(user, :read_secret_recipe, %{recipe_id: recipe_id}) do
      Permissions.can_read_secret_recipe?(user, recipe_id)
    end
  end

end
```

## Providing Insights

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