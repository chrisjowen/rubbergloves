defmodule RubberglovesTest do
  use ExUnit.Case
  doctest Rubbergloves

  @chris %RubberglovesTest.User{name: "chris"}
  @group1 %RubberglovesTest.Group{name: "group1"}
  @fred %RubberglovesTest.User{name: "fred"}

  test "cannot handle if not matched" do
    assert %Rubbergloves.Error{}= UserGloves.handle(@fred, :poision, %{}) |> IO.inspect
  end

  test "cannot handle if not matched without conditions" do
    assert %Rubbergloves.Error{}= UserGloves.handle(@fred, :poision) |> IO.inspect
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
    assert %Rubbergloves.Error{}= MultiPhaseUserGloves.handle(@group1, :anything) |> IO.inspect
  end

  test "can handle in later phase" do
    assert :ok = MultiPhaseUserGloves.handle(@chris, :handled_later)
  end

  test "can limit phases" do
    assert %Rubbergloves.Error{}= MultiPhaseUserGloves.handle(@chris, :handled_later, nil, [:default, :before]) |> IO.inspect
  end

end
