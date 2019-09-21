defmodule Rubbergloves.Errors.HandleError do
  defstruct [:reason, :args, children: []]
end
