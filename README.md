# Rubbergloves

A series of macros, and utilities to help hadling your elixir tonics.

# Motivation

Phoenix controllers aren't perticularly opnionated about when we should take user input and convert them to structs along with validating the input.
Additionally, authorization is left up to the user to decide what stratergy to use. 

Rubbergloves takes a more opinionated view that we should be working with Structs as soon as possible and have a consistent way of validating input whether in 
both controller methods and dependnet services/contexts/modules.

Ideally the flow would be:

- Taking controller params input in and convert them a Struct
- Run first line validations checks against the Struc and bomb out if its invalid
- Use use this Struct as conditions to check user authorization against a specific action
- If all well run then and only then execute the controller logic

# Installation

`{:rubbergloves, "~> 0.0.3"}`

# Docs

https://hexdocs.pm/rubbergloves/0.0.2/api-reference.html

# Example

1. Define your input struct, and `use Rubbergloves.Struct` to automatically define mapping. In this case we are mapping input with camelCase string maps given from params

```elixir
defmodule Example.Dto.LoginRequest do
  use Rubbergloves.Struct

  defstruct [:username, :password, :hashed_password]

  defmapping do
     keys &CamelCaseKeyResolver.resolve/1
     override :hashed_password, key: "password", value: &SuperSecretPasswordHasher.hash/1
  end

  # Validate however you like, just be sure to implment the Rubbergloves.Validation protocol to cast your result
  def validate(request) do
    request
    |> Justify.validate_required(:username)
    |> Justify.validate_required(:password)
  end

end
```

2. Define who can process these kinds of requests

```elixir
defmodule Example.DefaultUserGloves do
  use Rubbergloves.Handler, wearer: Example.User

  # Hardcoded rules checked first
  phase :pre_checks do
    can_handle!(%Example.User{role: :admin}, _any_action) # Admin can do anything
    can_handle!(%Example.User{name: "Christopher Owen"}, :update_user, request=%DTO.UpdateCredentialsRequest{}) # Hardcoded that I can update users
  end
  
  # If rejected check database to see if I have explicit permissions
  phase :registery_check do
    can_handle?(user, action, conditions) do
      Repo.one(from r in PermissionsRegistory, where r.user_id == ^user.id and r.action == ^action and r.conditions == ^conditions) != nil
    end  
  end
  
end

```

3. Use the annotations based controller bindings 

```elixir
defmodule Example.AuthController do
  use ExampleWeb, :controller
  use Rubbergloves.Annotations.ControllerAnnotations
  import Guardian.Plug
  alias Example.Dto
  alias Example.Accounts

  # Automatically binds the input to the LoginRequest defined above
  @bind Dto.LoginRequest
  def login(conn, _, request = %Dto.LoginRequest{}) do
    with {:ok, user} <- Accounts.login(request) do
      json(conn, user)
     end
  end

  # Automatically bind and checks the rules to see if this user can handle this kind of request
  @can_handle [action: :update_user, gloves: DefaultUserGloves,  principle_resolver: &current_resource/1]
  @bind Dto.UpdateCredentialsRequest
  def update_user(conn, _, request = %UpdateCredentialsRequest{}) do
    with {:ok, user} <- Accounts.update_user(request) do
      json(conn, user)
     end
  end

end
```



