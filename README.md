# HashMap

A (theoretical) exploration of a Concurrent HashMap using the Actor Pattern.

I'm looking at doing these things:
1. Support `get`, `set` and `delete` operations on the HashMap. (Keys can only be integers for now)
2. `get` requests should only be blocking until they're dispatched off to corresponding bucket.
3. Buckets should resize(and rehash) when their `@max_limit` is reached, while maintaining correctness in any order of `get` and `set`.
4. Batched reads in a bucket so that list traversal is minimised.
5. Benchmark/compare with other implementations.

## How to run

Once you have Erlang and Elixir installed, clone the repository and run
`mix test`.

A sample usage of the `HashMap` module is in the test file -> `hash_map_test.exs`.

