__precompile__()

module Dispatcher

export DispatchGraph,
    DispatchNode,
    DispatchResult,
    DataNode,
    IndexNode,
    Op,
    CollectNode,
    DispatcherError,
    DependencyError,
    add_edge!,
    nodes,
    dependencies,
    has_label,
    get_label,
    set_label!

export Executor,
    AsyncExecutor,
    ParallelExecutor,
    dispatch!,
    prepare!,
    run!

export @op

using AutoHashEquals
using Compat
using DataStructures
using DeferredFutures
using IterTools
using LightGraphs
using Memento
using ResultTypes

abstract type DispatcherError <: Exception end

const logger = getlogger(@__MODULE__)
const reset! = DeferredFutures.reset!  # DataStructures also exports this.

__init__() = Memento.register(logger)  # Register our logger at runtime.

include("nodes.jl")
include("graph.jl")
include("executors.jl")

end # module
