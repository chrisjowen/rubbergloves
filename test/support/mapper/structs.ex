defmodule Structs do
  defmodule Simple do
    use Rubbergloves.Struct

    defstruct [:a, :b, :c]
  end

  defmodule Nested do
    use Rubbergloves.Struct

    defstruct [:simple, d]
  end

  defmodule Other do
    use Rubbergloves.Struct

    defstruct [:a, :b, :c]
  end

  defmodule Bar do
    use Rubbergloves.Struct
    defstruct [:baz]

    defmapping do
      override :baz, key: &string_key_prefix/1, value: &times_two/1
    end

    defp times_two(input), do: input * 2
    defp string_key_prefix(key), do: "KEY_#{key}"
  end


  defmodule Foo do
    use Rubbergloves.Struct
    defstruct [:bar, :a]

    defmapping do
      keys &Atom.to_string/1
      override :a, key: "alt_a"
      override :bar, value: one(%Structs.Bar{}, Structs.Bar.mappings)
    end
  end

  defmodule Complex do
    defstruct [:foo, :weird_key, :derived_value, defaulted: "default"]
  end

end
