# Dispatcher

[![Build Status](https://travis-ci.org/invenia/Dispatcher.jl.svg?branch=master)](https://travis-ci.org/invenia/Dispatcher.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/urs1v0cp8shgdq3t/branch/master?svg=true)](https://ci.appveyor.com/project/iamed2/dispatcher-jl/branch/master)
[![codecov](https://codecov.io/gh/invenia/Dispatcher.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/Dispatcher.jl)

Dispatcher is a tool for building and executing a computation graph given a series of dependent operations.

Documentation: [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/Dispatcher.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/Dispatcher.jl/latest)

## Overview

Using Dispatcher, `run!` builds and runs a computation graph of `DispatchNode`s.
`DispatchNode`s represent units of computation that can be run.
The most common `DispatchNode` is `Op`, which represents a function call on some arguments.
Some of those arguments may exist when building the graph, and others may represent the results of other `DispatchNode`s.
An `Executor` executes a whole `DispatchGraph`.
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

> Isn't this just Dask?

Pretty much.
The plan is to implement another `Executor` and [integrate](https://github.com/dask/distributed/issues/586) with the [`dask.distributed`](https://distributed.readthedocs.io/) scheduler service to piggyback off of their great work.

> How does Dispatcher handle passing data?

Dispatcher uses Julia `RemoteChannel`s to pass data between dispatched `DispatchNode`s.
For more information on how data transfer works with Julia's parallel tools see their [documentation](http://docs.julialang.org/en/latest/manual/parallel-computing/).
