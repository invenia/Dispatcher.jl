# Dispatcher.jl

```@meta
CurrentModule = Dispatcher
```

## Overview

Using Dispatcher, a `DispatchContext` maintains a computation graph of `DispatchNode`s.
`DispatchNode`s represent units of computation that can be run.
The most common `DispatchNode` is `Op`, which represents a function call on some arguments.
Some of those arguments may exist when building the graph, and others may represent the results of other `DispatchNode`s.
An `Executor` executes a whole `DispatchContext`.
Two `Executor`s are provided.
`AsyncExecutor` executes computations asynchronously using Julia `Task`s.
`ParallelExecutor` executes computations in parallel using all available Julia processes (by calling `@spawn`).

## Frequently Asked Questions

> How is Dispatcher different from ComputeFramework/Dagger?

Dagger is built around distributing vectorized computations across large arrays.
Dispatcher is built to deal with discrete, heterogeneous data using any Julia functions.

> How is Dispatcher different from Arbiter?

Arbiter requires manually adding tasks and their dependencies and handling data passing.
Dispatcher automatically identifies dependencies from user code and passes data efficiently between dependencies.

> Isn't this just Dask

Pretty much.
The plan is to implement another `Executor` and [integrate](https://github.com/dask/distributed/issues/586) with the [`dask.distributed`](https://distributed.readthedocs.io/) scheduler service to piggyback off of their great work.

> How does Dispatcher handle passing data?

Dispatcher uses Julia `RemoteChannel`s to pass data between dispatched `DispatchNode`s.
For more information on how data transfer works with Julia's parallel tools see their [documentation](http://docs.julialang.org/en/latest/manual/parallel-computing/).

## Documentation Contents

```@contents
Pages = ["pages/manual.md", "pages/api.md"]
```
