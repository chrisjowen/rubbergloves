defmodule RubberglovesTest do
  use ExUnit.Case
  alias RubberglovesTest.UserGloves

  @chris %RubberglovesTest.User{name: "chris"}
  @group1 %RubberglovesTest.Group{name: "group1"}
  @fred %RubberglovesTest.User{name: "fred"}
  alias Rubbergloves.Errors.HandleError


  test "cannot handle if not matched" do
    assert %HandleError{}= UserGloves.handle(@fred, :poision, %{})
  end

  test "cannot handle if not matched without conditions" do
    assert %HandleError{}= UserGloves.handle(@fred, :poision)
  end

  test "can handle if conditions match with true return" do
    assert :ok = UserGloves.handle(@fred, :poision, %{valid: true})
  end

  test "can handle with principle match" do
    assert :ok = UserGloves.handle(@chris, :poision)
  end

  test "can handle with any principle match" do
    assert :ok = UserGloves.handle(@chris, :anything)
  end

  test "can handle with registy match with map" do
    assert :ok = MultiPhaseUserGloves.handle(@chris, :anything)
  end

  test "cannot handle with different wearer" do
    assert %HandleError{}= MultiPhaseUserGloves.handle(@group1, :anything)
  end

  test "can handle in later phase" do
    assert :ok = MultiPhaseUserGloves.handle(@chris, :handled_later)
  end

  test "can limit phases" do
    assert %HandleError{}= MultiPhaseUserGloves.handle(@chris, :handled_later, nil, [:default, :before])
  end

end
