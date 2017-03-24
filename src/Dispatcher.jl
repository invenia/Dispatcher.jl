module Dispatcher

export DispatchContext,
    DispatchGraph,
    DispatchNode,
    DispatchResult,
    DataNode,
    IndexNode,
    Op,
    DependencyError,
    add_edge!,
    nodes,
    dependencies,
    add!

export Executor,
    AsyncExecutor,
    ParallelExecutor,
    dispatch!,
    prepare!,
    run!

export @dispatch_context,
    @op,
    @node,
    @component,
    @include

using AutoHashEquals
using DataStructures
using DeferredFutures
using Iterators
using LightGraphs
using Memento
using ResultTypes

abstract DispatcherError <: Exception

logger = get_logger(current_module())

include("nodes.jl")
include("graph.jl")
include("context.jl")
include("executors.jl")
include("macros.jl")

end # module
