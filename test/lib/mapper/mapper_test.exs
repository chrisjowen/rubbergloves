defmodule MapperTest do
  use ExUnit.Case
  alias Rubbergloves.Mapper.{Options, Override, AtomKeyResolver, StringKeyResolver, DynamicKeyResolver}

  test "Can map simple from string key Map" do
    options = %Options{
      keys: &StringKeyResolver.resolve/2
    }

    result = Rubbergloves.Mapper.map(%Structs.Simple{}, %{"a" => "a", "b" => "b", "c" => "c"}, options)
    assert result == %Structs.Simple{a: "a", b: "b", c: "c"}
  end

  test "Can map simple from atom key Map" do
    options = %Options{
      keys: &AtomKeyResolver.resolve/2
    }

    result = Rubbergloves.Mapper.map(%Structs.Simple{}, %{a: "a", b: "b", c: "c"}, options)
    assert result == %Structs.Simple{a: "a", b: "b", c: "c"}
  end


  test "Can map simple from mixed key Map" do
    options = %Options{
      keys: &DynamicKeyResolver.resolve/2
    }

    params = Map.merge(%{"a" => "a", "b" => "b"}, %{c: "c"})
    result = Rubbergloves.Mapper.map(%Structs.Simple{}, params, options)
    assert result == %Structs.Simple{a: "a", b: "b", c: "c"}
  end



  test "Canjunk" do

    params = Map.merge(%{"a" => "a", "b" => "b"}, %{c: "c"})
    result = SimpleMapper.map(Structs.Simple, params)
    assert result == %Structs.Simple{a: "a", b: "b", c: "c"}
  end

end

# defmodule ExMapperSpec do
#   use ESpec
#   alias ExMapper.{Options, Override}

#   it "Can map simple from atom key Map" do
#     result = ExMapper.map(%Structs.Simple{}, %{ a: "a", b: "b", c: "c"})
#     expected = %Structs.Simple{ a: "a", b: "b", c: "c"}
#     result |> should(be(expected))
#   end

#   it "Can map simple from atom key Map" do
#     opts = %Options{keys: :stringified}
#     result = ExMapper.map(%Structs.Simple{}, %{ "a" => "a", "b" => "b", "c" => "c"}, opts)
#     expected = %Structs.Simple{ a: "a", b: "b", c: "c"}
#     result |> should(be(expected))
#   end

#   it "Can map simple from key function" do
#     opts = %Options{keys: fn(key) ->
#         string_key = Atom.to_string(key)
#         string_key <> string_key |> String.to_atom
#       end
#     }
#     result = ExMapper.map(%Structs.Simple{}, %{ aa: "a", bb: "b", cc: "c"}, opts)
#     expected = %Structs.Simple{ a: "a", b: "b", c: "c"}
#     result |> should(be(expected))
#   end

#   it "Can override for a single key" do
#     opts = %Options{
#       overrides: %{
#         b: %Override {
#           key: :override
#         }
#       }}

#     result = ExMapper.map(%Structs.Simple{}, %{ a: "a", override: "b", c: "c"}, opts)
#     expected = %Structs.Simple{ a: "a", b: "b", c: "c"}
#     result |> should(be(expected))
#   end

#   it "Can override for a single key with a function" do
#     opts = %Options{
#       overrides: %{
#         b: %Override {
#           key: fn(_key) -> :override end
#         }
#       }}
#     result = ExMapper.map(%Structs.Simple{}, %{ a: "a", override: "b", c: "c"}, opts)
#     expected = %Structs.Simple{ a: "a", b: "b", c: "c"}
#     result |> should(be(expected))
#   end

#   it "Can override value" do
#     opts = %Options{
#       overrides: %{
#         b: %Override {
#           value: fn(_value) -> "d" end
#         }
#       }}

#     result = ExMapper.map(%Structs.Simple{}, %{ a: "a", b: "b", c: "c"}, opts)
#     expected = %Structs.Simple{ a: "a", b: "d", c: "c"}
#     result |> should(be(expected))
#   end

#   it "Can override value with nested mapping" do
#     opts = %Options{
#       overrides: %{
#         bar: %Override {
#           value: &ExMapper.map(%Structs.Bar{}, &1)
#         }
#       }}

#     result = ExMapper.map(%Structs.Foo{}, %{ bar: %{ baz: "a"} }, opts)
#     expected = %Structs.Foo{ bar: %Structs.Bar{ baz: "a"} }
#     result |> should(be(expected))
#   end

#   it "Can compose with complex mapping" do
#     bar_opts = %Options{
#       overrides: %{
#         baz: %Override {
#           key: "bamboo"
#         }
#       }}

#     foo_opts = %Options{
#       overrides: %{
#         bar: %Override {
#           value: &ExMapper.map(%Structs.Bar{}, &1, bar_opts)
#         }
#       }}

#     comlex_opts = %Options{
#       overrides: %{
#         foo: %Override {
#           value: &ExMapper.map(%Structs.Foo{}, &1, foo_opts)
#         },
#         weird_key: %Override {
#           key: :"Som3_bIzzar3_k3Y"
#         },
#         derived_value: %Override {
#           value: fn(value) -> value + value end
#         },
#       }}

#       input = %{
#         foo: %{
#           bar: %{
#             "bamboo" => "tree"
#           }
#         },
#         "Som3_bIzzar3_k3Y":  "asdasd",
#         derived_value: 10
#       }

#       expected = %Structs.Complex{
#            defaulted: "default",
#            derived_value: 20,
#            foo: %Structs.Foo{
#              bar: %Structs.Bar{
#                baz: "tree"
#                }
#             },
#             weird_key: "asdasd"
#            }

#     ExMapper.map(%Structs.Complex{}, input, comlex_opts) |> should(be(expected))
#   end

#   it "Can map from dsl options" do
#     input = %{
#         "alt_a" => "adssad",
#         "bar" => %{
#           "KEY_baz" => 100,
#         }
#     }

#     expected = %Structs.Foo{
#       a: "adssad",
#       bar: %Structs.Bar{baz: 200}
#     }

#     ExMapper.map(%Structs.Foo{}, input, Structs.Foo.mappings) |> should(be(expected))
#   end

# end
