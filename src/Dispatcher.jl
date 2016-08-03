module Dispatcher

export DispatchContext,
    DispatchGraph,
    DispatchNode,
    DataNode,
    Op,
    add_edge!,
    nodes,
    dependencies,
    add!

export Executor,
    AsyncExecutor,
    ParallelExecutor,
    dispatch!,
    run!

export @dispatch_context,
    @op,
    @node

using AutoHashEquals
using DataStructures
using DeferredFutures
using Iterators
using LightGraphs

abstract DispatcherError

include("nodes.jl")
include("graph.jl")
include("context.jl")
include("executors.jl")
include("macros.jl")

end # module
