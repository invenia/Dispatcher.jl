# Manual

## Motivation

`Dispatcher.jl` is designed to distribute and manage execution of a graph of computations.
These computations are specified in a manner as close to regular imperative Julia code as possible.
Using a parallel executor with several processes, a central controller manages execution, but data is transported only among processes which will use it.
This avoids having one large process where all data currently being used is stored.

## Design

### Overview

Using Dispatcher, `run!` builds and runs a computation graph of `DispatchNode`s.
`DispatchNode`s represent units of computation that can be run.
The most common `DispatchNode` is `Op`, which represents a function call on some arguments.
Some of those arguments may exist when building the graph, and others may represent the results of other `DispatchNode`s.
An `Executor` builds and executes a whole `DispatchGraph`.
Two `Executor`s are provided.
`AsyncExecutor` executes computations asynchronously using Julia `Task`s.
`ParallelExecutor` executes computations in parallel using all available Julia processes (by calling `@spawn`).

Here is an example defining and executing a graph:

```julia
filenames = ["mydata-$d.dat" for d in 1:100]
data = [(@op load(filename)) for filename in filenames]

reference = @op load_from_sql("sql://mytable")
processed = [(@op process(d, reference)) for d in data]

rolled = map(1:(length(processed) - 2)) do i
    a = processed[i]
    b = processed[i + 1]
    c = processed[i + 2]
    roll_result = @op roll(a, b, c)
    return roll_result
end

compared = map(1:200) do i
    a = rand(rolled)
    b = rand(rolled)
    compare_result = @op compare(a, b)
    return compare_result
end

best = @op reduction(CollectNode(compared))

executor = ParallelExecutor()
(run_best,) = run!(executor, [best])
```

The components of this example will be discussed below.
This example is based on [a Dask example](http://matthewrocklin.com/blog/work/2017/01/24/dask-custom).

### Dispatch Nodes

A `DispatchNode` generally represents a unit of computation that can be run.
`DispatchNode`s are constructed when defining the graph and are run as part of graph execution.
`CollectNode` from the above example is a subtype of `DispatchNode`.

Any arguments to `DispatchNode` constructors (including in `@op`) which are `DispatchNode`s are recorded as dependencies in the graph.

### Op

An `Op` is a `DispatchNode` which represents some function call to be run as part of graph execution.
This is the most common type of `DispatchNode`.
The `@op` macro deconstructs a function call to construct an `Op`.
The following code:

```julia
roll_result = @op roll(a, b, c)
```

is equivalent to:

```julia
roll_result = Op(roll, a, b, c)
```

Note that code in the argument list gets evaluated immediately; only the function call is delayed.

### Executors

An `Executor` runs a `DispatchGraph`.
This package currently provides two `Executor`s: `AsyncExecutor` and `ParallelExecutor`.
They work the same way, except `AsyncExecutor` runs nodes using `@async` and `ParallelExecutor` uses `@spawn`.

This call:

```julia
(run_best,) = run!(executor, [best])
```

takes an `Executor` and a `Vector{DispatchNode}`, creates a `DispatchGraph` of those nodes and all of their ancestors, runs it, and returns a collection of `DispatchResult`s (in this case containing only the `DispatchResult` for `best`).
A `DispatchResult` is a [`ResultType`](https://github.com/iamed2/ResultTypes.jl) containing either a `DispatchNode` or a `DependencyError` (an error that occurred when attempting to satisfy the requirements for running that node).

It is also possible to feed in inputs in place of nodes in the graph; see [`run!`](api.html#Dispatcher.run!-Tuple{Dispatcher.Executor,AbstractArray{T<:Dispatcher.DispatchNode,N},AbstractArray{S<:Dispatcher.DispatchNode,N}}) for more.

## Further Reading

Check out the [API](@ref) for more information.
