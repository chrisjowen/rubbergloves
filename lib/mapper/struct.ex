defmodule Rubbergloves.Struct  do
  @moduledoc"""
  A series of macros to define how to convert from a raw %{} map to a well defined struct.

  Supports nested struct mapping, and global conventions.
  Using *Rubbergloves.Struct* give you access to the `defmapping` module that defines how to convert the input into your stuct.

  Once in a defmapping block, two macros are avaliable for you:

  - *keys/1*

    Takes a function that retrieves the key of the struct and returns the key in the map to collect the data from.

    i.e. to map input in the form `%{ "someKeyName" => "value"}` to a struct like `defstruct [:some_key_name]`

  - *overrides/2*

    Takes the struct key and a keyword list of override options.

  Override options can include:

  :key
    - A string/atom value of the key in the input map
    - Or a function in the format struct_key -> expected_key

  :value
    - A hard coded value to use despite whats in the input map.
    - Or more useful a function in the format input_value -> transformed_value
    - For nested structs, use the one/many macros to apply nested mapping rules


  ### Given Input
  ```
  params = %{
    "username" => "test",
    "password" => "password"
    "meta" => %{
      "type" => "UserPass"
    }
  }
  ```
  ### With Definitions
  ```
  defmodule MyApp.Requests.LoginRequestMeta do
      defstruct [:type ]

    defmapping do
      keys &CamelCaseKeyResolver.resolve/1
    end
  end

  defmodule MyApp.Requests.LoginRequest do
    use Rubbergloves.Struct
    alias  MyApp.Requests.LoginRequestMeta

    defstruct [:username, :password, :hashed_password, :meta]

    defmapping do
      keys &CamelCaseKeyResolver.resolve/1
      override :hashed_password, key: "password", value: &hash_password_input/1
      override :meta, value: one(LoginRequestMeta)
    end

    @impl validate
    def validate(request) do
      # Validate however you like
    end

    # Custom methods to map your input to struct values
    def hash_password_input(_val) do
      "SOMEHASHED_PASSWORD_EXAMPLE"
    end

  end
  ```
  """

  alias Rubbergloves.Mapper

  defmacro __using__(_) do
    quote do
      require Rubbergloves.Struct
      import Rubbergloves.Struct
      alias Rubbergloves.Util.CamelCaseKeyResolver
      alias Rubbergloves.Mapper
      @before_compile { unquote(__MODULE__), :__before_compile__ }
      @mappings %Mapper.Options{}

      @callback validate(%__MODULE__{}) :: :ok | {:error, any()}

      def many(struct, opts \\ %Mapper.Options{}), do: &many(struct, &1, opts)
      defp many(struct, value, opts) when is_list(value), do: value |> Enum.map(&one(struct, &1, opts))
      defp many(_, _, _), do: []

      def one(struct, opts \\ %Mapper.Options{}), do: &one(struct, &1, opts)
      defp one(struct, val, opts), do: Mapper.map(struct, val, opts)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def mappings(), do: @mappings
      def validate(%__MODULE__{}), do: :ok
      def validate(any), do: :invalid_type
    end
  end

  defmacro defmapping(block) do
    quote do
      unquote(block)
    end
  end

  defmacro keys(val) do
    func_name = "keys_func" |> String.to_atom
    use_value_default = is_atom(val)

    quote do
      if(!unquote(use_value_default)) do
        localize_function(unquote(func_name), unquote(val))
      end

      @mappings Map.put(@mappings, :keys,
        if(unquote(use_value_default), do: unquote(val), else: &__MODULE__.unquote(func_name)/1)
      )
    end
  end

  defmacro override(struct_key, override) do
    key = Keyword.get(override, :key, :default)
    value = Keyword.get(override, :value, :default)
    key_func_name = "#{struct_key}_key" |> String.to_atom
    value_func_name = "#{struct_key}_value" |> String.to_atom

    # Note: Akward that we must do this here, but we cannot evaluate the value of key/value in quote incase its a missing local function
    use_key_default = key == :default
    use_value_default = value == :default

    quote do
      localize_function(unquote(key_func_name), unquote(key))
      localize_function(unquote(value_func_name), unquote(value))

      overrides = Map.put(Map.get(@mappings, :overrides), unquote(struct_key), %Mapper.Override{
        key: if(unquote(use_key_default), do: :default, else: &__MODULE__.unquote(key_func_name)/1),
        value: if(unquote(use_value_default), do: :default, else: &__MODULE__.unquote(value_func_name)/1)
      })
      @mappings Map.put(@mappings, :overrides, overrides)
    end
  end

  defmacro localize_function(name, defenition) do
    if(is_tuple(defenition)) do
      quote do
        def unquote(name)(input), do: unquote(defenition).(input)
      end
    else
      quote do
        def unquote(name)(input), do: unquote(defenition)
      end
    end
  end

end
