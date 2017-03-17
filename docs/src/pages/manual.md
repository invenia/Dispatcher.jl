# Manual

## Motivation

`Dispatcher.jl` is designed to distribute and manage execution of a graph of computations.
These computations are specified in a manner as close to regular imperative Julia code as possible.
Using a parallel executor with several processes, a central controller manages execution, but data is transported only among processes which will use it.
This avoids having one large process where all data currently being used is stored.

### FAQ

> How is Dispatcher different from ComputeFramework/Dagger?

Dagger is built around distributing vectorized computations across large arrays.
Dispatcher is built to deal with discrete, heterogeneous data using any Julia functions.

> How is Dispatcher different from Arbiter?

Arbiter requires manually adding tasks and their dependencies and handling data passing.
Dispatcher automatically identifies dependencies from user code and passes data efficiently between dependencies.

> How does Dispatcher handle passing data?

Dispatcher uses Julia `RemoteChannel`s to pass data between dispatched `DispatchNode`s.
For more information on how data transfer works with Julia's parallel tools see their [documentation](http://docs.julialang.org/en/latest/manual/parallel-computing/).


## Design

### Overview

Using Dispatcher, a `DispatchContext` maintains a computation graph of `DispatchNode`s.
`DispatchNode`s represent units of computation that can be run.
The most common `DispatchNode` is `Op`, which represents a function call on some arguments.
Some of those arguments may exist when building the graph, and others may represent the results of other `DispatchNode`s.
An `Executor` executes a whole `DispatchContext`.
Two `Executor`s are provided.
`AsyncExecutor` executes computations asynchronously using Julia `Task`s.
`ParallelExecutor` executes computations in parallel using all available Julia processes (by calling `@spawn`).

Here is an example defining and executing a graph:

```julia

```

The components of this example will be discussed below.

### Dispatch Nodes

A `DispatchNode` generally represents a unit of computation that can be run.
`DispatchNode`s are constructed when defining the graph and are run as part of graph execution.
The `@node` macro takes a `DispatchNode` instance and adds it to the graph in the current context.
The following code, where `Feature <: DispatchNode`:

```julia

```

is equivalent to:

```julia

```

where `ctx` is the current dispatch context.

### Op

An `Op` is a `DispatchNode` which represents some function call to be run as part of graph execution.
This is the most common type of `DispatchNode`.
The `@op` applies an extra transformation on top of the `@node` macro and deconstructs a function call to add to the graph.
The following code:

```julia

```

is equivalent to:

```julia

```

where `ctx` is the current dispatch context.
Note that code in the argument list gets evaluated immediately; only the function call is delayed.

### Dispatch Context and Dispatch Graph

The above macros add nodes to a `DispatchContext`. The `DispatchContext` contains a `DispatchGraph`, which stores nodes and dependencies in a graph.
Any arguments to `DispatchNode` constructors (including in `@node` and `@op`) which are `DispatchNode`s are recorded as dependencies in the graph.

### Executors


