defmodule HashMap do
  use GenServer
  @bucket_count 10 #Initially set to 10. Will expand as necessary

  #Client Functions
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def set(pid, key, value) do
    GenServer.cast(pid, {:set, key, value})
  end

  def delete(pid, key) do
    GenServer.cast(pid, {:delete, key})
  end

  #Callbacks
  def init([]) do
    state = %{
      bucket_count: @bucket_count,
      buckets: init_buckets(@bucket_count)
    }
    {:ok, state}
  end

  def init_buckets(count) do
    (1..@bucket_count)
    |> Enum.map(fn _i ->
      {:ok, bucket_pid} = Bucket.start_link({:parent_pid, self()})
      bucket_pid
    end)
    |> List.to_tuple
  end

  @doc """
  Determines the index of the bucket to search for, given
  a key. Currently:
  (1) Assumes keys are integers
  (2) modulo function
  """
  def hash_function(key, state) do
    rem(key, state[:bucket_count])
  end

  def handle_call({:get, key}, from, state) do
    bucket_id = hash_function(key, state)
    bucket = elem(state[:buckets], bucket_id)
    GenServer.cast(bucket, {:get, key, from})
    {:noreply, state}
  end

  def handle_cast({:set, key, value}, state) do
    bucket_id = hash_function(key, state)
    bucket = elem(state[:buckets], bucket_id)
    GenServer.cast(bucket, {:set, key, value})
    {:noreply, state}
  end

  def handle_cast({:delete, key}, state) do
    bucket_id = hash_function(key, state)
    bucket = elem(state[:buckets], bucket_id)
    GenServer.cast(bucket, {:delete, key})
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end