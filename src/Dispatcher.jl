module Dispatcher

# ONLY NECESSARY ON 0.5
if VERSION < v"0.6-"
    function asyncmap(f, c...; ntasks=0)
        collect(Base.AsyncGenerator(f, c...; ntasks=ntasks))
    end
else
    asyncmap = Base.asyncmap
end

export DispatchContext,
    DispatchGraph,
    DispatchNode,
    DispatchResult,
    DataNode,
    IndexNode,
    Op,
    CollectNode,
    DependencyError,
    add_edge!,
    nodes,
    dependencies,
    add!,
    has_label,
    get_label,
    set_label!

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

const logger = get_logger(current_module())

include("nodes.jl")
include("graph.jl")
include("context.jl")
include("executors.jl")
include("macros.jl")

end # module
