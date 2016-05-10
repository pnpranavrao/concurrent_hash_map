defmodule HashMapTest do
  use ExUnit.Case
  doctest HashMap

  setup do
    {:ok, map} = HashMap.start_link
    {:ok, %{map: map}}
  end

  test "basic set,get,delete works", context do
    map = context[:map]
    assert HashMap.get(map, 3) == nil
    HashMap.set(map, 3, "Three")
    assert HashMap.get(map, 3) == "Three"
    HashMap.delete(map, 3)
    assert HashMap.get(map, 3) == nil
  end
end
