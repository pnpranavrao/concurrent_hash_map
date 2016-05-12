defmodule Counter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__,[])
  end

  def init([]) do
    state = %{get: 0, set: 0, delete: 0}
    :timer.start
    :timer.send_interval(1000, {:print_output})
    {:ok, state}
  end

  def handle_info({:print_output}, state) do
    if state[:get] > 0, do: IO.inspect state
    {:noreply, %{get: 0, set: 0, delete: 0}}
  end

  def handle_cast(command, state) do
    new_state = case command do
      :get -> Map.put(state, :get, state[:get]+1)
      :set -> Map.put(state, :set, state[:set]+1)
      :delete -> Map.put(state, :delete, state[:delete]+1)
    end
    {:noreply, new_state}
  end
end