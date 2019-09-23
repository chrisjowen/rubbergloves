defmodule Rubbergloves do
  @moduledoc"""
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
  """

end
