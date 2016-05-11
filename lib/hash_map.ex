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
      buckets: init_buckets(@bucket_count, 0),
      overfill_count: 0, # No. of buckets overfilled.
      generation: 0
    }
    {:ok, state}
  end

  def handle_call({:get, key}, from, state) do
    bucket_id = hash_function(key, state[:bucket_count])
    bucket = elem(state[:buckets], bucket_id)
    GenServer.cast(bucket, {:get, key, from})
    {:noreply, state}
  end

  def handle_cast({:set, key, value}, state) do
    bucket_id = hash_function(key, state[:bucket_count])
    bucket = elem(state[:buckets], bucket_id)
    GenServer.cast(bucket, {:set, key, value})
    {:noreply, state}
  end

  def handle_cast({:delete, key}, state) do
    bucket_id = hash_function(key, state[:bucket_count])
    bucket = elem(state[:buckets], bucket_id)
    GenServer.cast(bucket, {:delete, key})
    {:noreply, state}
  end

  def handle_cast({:bucket_overflow, generation}, state) do
    if generation == state[:generation] do
      state = Map.put(state, :overfill_count, state[:overfill_count]+1)
      if (state[:overfill_count] > state[:bucket_count]/2) do
          GenServer.cast(self(), {:rehash, state[:generation]})
      end
    end
    {:noreply, state}
  end

  def handle_cast({:rehash, generation}, state) do
    if generation == state[:generation] do
      new_state = rehash(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  #Helper functions
  def init_buckets(count, generation) do
    (1..count)
    |> Enum.map(fn _i ->
      {:ok, bucket_pid} = Bucket.start_link({:parent_pid, self()},
                             {:generation, generation})
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
  def hash_function(key, bucket_count) do
    rem(key, bucket_count)
  end

  def rehash(state) do
    IO.inspect "Rehashing to #{state[:bucket_count]*2}"
    new_bucket_count = state[:bucket_count]*2
    new_buckets = init_buckets(new_bucket_count, state[:generation]+1)
    Tuple.to_list(state[:buckets])
    |> Enum.each(fn(bucket) ->
      GenServer.call(bucket, {:dump_all})
      |> Enum.each(fn({key, val}) ->
        new_bucket_id = hash_function(key, new_bucket_count)
        new_bucket = elem(new_buckets, new_bucket_id)
        GenServer.cast(new_bucket, {:set, key, val})
      end)
      GenServer.cast(bucket, {:stop})
    end)
    IO.inspect "Rehashing to #{state[:bucket_count]*2} done"
    #New State
    %{
      buckets: new_buckets,
      bucket_count: new_bucket_count,
      overfill_count: 0,
      generation: state[:generation] + 1
    }
  end
end

# val = :value
# {:ok, map} = HashMap.start_link
# reader = fn(map) -> (1..500_000) |> Enum.each(&HashMap.get(map,&1)); IO.inspect "reading done" end
# writer = fn(map) -> (1..500_000) |> Enum.each(&HashMap.set(map,&1,val)); IO.inspect "writing done"end