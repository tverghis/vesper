defmodule VesperTest do
  use ExUnit.Case
  doctest Vesper

  test "greets the world" do
    assert Vesper.hello() == :world
  end
end
