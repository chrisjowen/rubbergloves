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

# Insatllation

`{:rubbergloves, "~> 0.0.1"}`

# Example

```
defmodule Example.AuthController do
  use ExampleWeb, :controller
  use Rubbergloves.Controller

  action_fallback(Example.FallbackController)
  
  import Guardian.Plug
  alias Example.Dto
  alias Example.Authorization.DefaultUserGloves
  alias Example.Accounts

  @handler_defaults [
    gloves: DefaultUserGloves,
    principle_resolver: &current_resource/1
  ]

  @bind request: Dto.LoginRequest
  def login(conn, _, request: login_request) do
    with {:ok, user} <- Accounts.login(login_request) do
      json(conn, user)
     end
  end

  @bind request: Dto.UpdateCredentialsRequest
  @can_handle :update_user, :request, Example.DefaultUserGloves
  def update_user(conn, _, request: update_user_request) do
    with {:ok, user} <- Accounts.update_user(update_user_request) do
      json(conn, user)
     end
  end

end

defmodule Example.Dto.LoginRequest do
  use Rubbergloves.Struct

  defstruct [:username, :password, :hashed_password]

  defmapping do
     keys &CamelCaseKeyResolver.resolve/1
     override :hashed_password, key: "password", value: &hash_password_input/1
  end

  def validate(request) do
    request
    |> Justify.validate_required(:username)
    |> Justify.validate_required(:password)
  end

  def hash_password_input(val) do
    # TODO: Hash password
    "SOMEHASHED_PASSWORD_EXAMPLE"
  end

end

defmodule Example.DefaultUserGloves do
  use Rubbergloves.Handler, wearer: Example.User

  # Hardcoded rules checked first
  phase :pre_checks do
    can_handle!(%Example.User{role: :admin}, _any_action) # Admin can do anything
    can_handle!(%Example.User{name: "Christopher Owen"}, :update_user, request=%DTO.UpdateCredentialsRequest{}) # Hardcoded that I can update users
    cannot_handle!(_anyone, _any_action) # everyone else CANNOT do anything
  end
  
  # If rejected check database to see if I have explicit permissions
  phase :registery_check do
    can_handle?(user, action, conditions) do
      Repo.one(from r in PermissionsRegistory, where r.user_id == ^user.id and r.action == ^action and r.conditions == ^conditions) != nil
    end  
  end
  
end