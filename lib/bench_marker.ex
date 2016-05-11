defmodule Benchmarker do

  def setup do
    {:ok, map} = HashMap.start_link
    IO.inspect "First doing full write"
    writer(map, 1)
    {:ok, map}
  end

  def benchmark(map) do
    IO.inspect "Spawning 7 read threads"
    (1..7) |> Enum.each(fn name -> spawn(fn -> reader(map, name) end) end)
    IO.inspect "Spawning 1 write thread"
    (1..1) |> Enum.each(fn name -> spawn(fn -> writer(map, name) end) end)
    IO.inspect "Spawning 1 delete thread"
    (1..1) |> Enum.each(fn name -> spawn(fn -> deleter(map, name) end) end)
  end

  def reader(map, name) do
    IO.inspect "reader #{name} start"
    (1..250_000) |> Enum.each(&HashMap.get(map,&1))
    IO.inspect "reader #{name} done"
  end

  def writer(map, name) do
    val = :value #Storing an atom to save memory
    IO.inspect "writer #{name} start"
    (1..250_000) |> Enum.each(&HashMap.set(map,&1,val))
  end

  def deleter(map, name) do
    IO.inspect "deleter #{name} start"
    (1..1000)
    |> Enum.each(fn(_) ->
      (1..250)
      |> Enum.each(&HashMap.delete(map,&1))
    end)
  end
end