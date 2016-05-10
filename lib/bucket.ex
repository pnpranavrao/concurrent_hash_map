defmodule Bucket do
  use GenServer
  @max_limit 20 #Max length of List in a bucket

  #Client functions
  def start_link({:parent_pid, parent}) do
    GenServer.start_link(__MODULE__, [{:parent_pid, parent}])
  end

  #Callbacks
  def init([{:parent_pid, pid}]) do
    state = %{
      list: [],
      parent_pid: pid
   }
   {:ok, state}
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
  def set(key_value, %{list: list} = state) do
    %{state| list: [key_value | list]}
  end

  def get(req_key, %{list: list}) do
    result =
    list |> Enum.find(nil, fn({key, val}) -> req_key == key end)
    case result do
      nil -> nil
      {key, val} -> val
    end
  end

  def delete(req_key, %{list: list} = state) do
    new_list =
    list |> Enum.reject(fn({key, _val}) -> key == req_key end)
    %{state | list: new_list}
  end
end