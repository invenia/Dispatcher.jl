module Dispatcher

export DispatchContext,
    DispatchGraph,
    DispatchNode,
    DataNode,
    Op,
    add_edge!,
    dependencies

export Executor,
    AsyncExecutor,
    ParallelExecutor,
    dispatch!,
    run!

using AutoHashEquals
using DataStructures
using DeferredFutures
using Iterators
using LightGraphs

include("nodes.jl")
include("graph.jl")
include("context.jl")
include("executors.jl")

end # module
