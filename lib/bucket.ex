defmodule Bucket do
  use GenServer
  @max_limit 10 #Max length of List in a bucket

  #Client functions
  def start_link({:parent_pid, parent}, {:generation, generation}) do
    GenServer.start_link(__MODULE__, [{:parent_pid, parent}, {:generation, generation}])
  end

  #Callbacks
  def init([{:parent_pid, pid}, {:generation, generation}]) do
    state = %{
      list: [],
      parent_pid: pid,
      element_count: 0,
      generation: generation
   }
   {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def handle_call({:dump_all}, _from, state) do
    {:reply, dump_all(state), state}
  end

  def handle_cast({:stop}, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:get, key, requester}, state) do
    GenServer.reply(requester, get(key, state))
    {:noreply, state}
  end

  def handle_cast({:set, key, val}, state) do
    new_state = set({key, val}, state)
    {:noreply, new_state}
  end
  def handle_cast({:delete, key}, state) do
    new_state = delete(key, state)
    {:noreply, new_state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  #Helper functions
  @doc """
  Updates the internal state of the list with the new element
  Will have to implement max_length check here.
  """
  def set(key_value, %{list: list, element_count: count} = state) do
    %{new_list: new_list, exists: exists} =
    list
    |> Enum.reduce(%{new_list: [], exists: false},
      fn({key, val}, acc) ->
                            if key == elem(key_value, 0) do
                              changes = %{new_list: [key_value | acc[:new_list]], exists: true}
                              Map.merge(acc, changes)
                            else
                              changes = %{new_list: [{key, val} | acc[:new_list]]}
                              Map.merge(acc, changes)
                            end
      end)
    if exists do
      %{state| list: new_list}
    else
      if count == @max_limit do
        GenServer.cast(state[:parent_pid], {:bucket_overflow, state[:generation]})
      end
      %{state| list: [key_value | list], element_count: count+1}
    end
  end

  def get(req_key, %{list: list}) do
    result =
    list |> Enum.find(nil, fn({key, val}) -> req_key == key end)
    case result do
      nil -> nil
      {key, val} -> val
    end
  end

  def delete(req_key, %{list: list, element_count: count} = state) do
    %{new_list: new_list, flag: flag} =
    list |> Enum.reduce(%{new_list: [], flag: false},
      fn({key, val}, acc) -> if key == req_key, do: %{acc | flag: true},
                            else: %{acc | new_list: [{key, val} | acc[:new_list]]}
      end)
    if flag do
      changes = %{list: new_list, element_count: count-1}
      Map.merge(state, changes)
    else
      state
    end
  end

  def dump_all(state) do
    state[:list]
  end
end