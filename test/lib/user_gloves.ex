
defmodule UserGloves do
  use Rubbergloves, wearer: RubberglovesTest.User

  can_handle!(%RubberglovesTest.User{name: "fred"}, _action, %{valid: true})
  can_handle!(%RubberglovesTest.User{name: "chris"}, :poision)
  can_handle!(_, :anything)

end
