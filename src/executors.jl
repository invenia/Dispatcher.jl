"""
Handles execution of `DispatchContext`s.

A type `T <: Executor` must implement `run!(::T, ::DispatchContext)`
and may optionally implement `run!(::T, ::DispatchNode)`.
"""
abstract Executor

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
run!(exec::Executor, node::DispatchNode) = nothing

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
Base.run(exec::Executor, node::DispatchNode) = nothing

"""
An Executor-agnostic `run!` method for `Op` which stores its function's
output in its `result` `DeferredFuture`.
"""
function run!(exec::Executor, op::Op)
    return put!(op.result, run(exec, op))
end

function Base.run(exec::Executor, op::Op)
    return op.func(op.args...; op.kwargs...)
end

function run!(exec::Executor, ctx::DispatchContext, nodes::AbstractArray{DispatchNode})
    reduced_ctx = copy(ctx)
    reduced_ctx.graph = ancestor_subgraph(ctx.graph, nodes)
    run!(exec, reduced_ctx)

    return nodes
end

function Base.run(exec::Executor, ctx::DispatchContext, nodes::AbstractArray{DispatchNode})
    node_nums = Int[ctx.graph.nodes[node] for node in nodes]
    reduced_ctx = deepcopy(ctx)
    new_nodes = DispatchNode[reduced_ctx.graph.nodes[node_num] for node_num in node_nums]
    reduced_ctx.graph = ancestor_subgraph(reduced_ctx.graph, nodes)
    run!(exec, reduced_ctx)

    return new_nodes
end

function Base.run(exec::Executor, ctx::DispatchContext)
    return run!(exec, deepcopy(ctx))
end


"""
`AsyncExecutor` is an Executor which spawns a local Julia `Task` for each
`DispatchNode` and waits for them to complete.
`AsyncExecutor`'s `run!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type AsyncExecutor <: Executor
end

function run!(exec::AsyncExecutor, ctx::DispatchContext)
    @sync begin
        for i = 1:length(ctx.graph.nodes)
            if !isready(ctx.graph.nodes[i])
                @async begin
                    node = ctx.graph.nodes[i]
                    fetch_deps!(node)
                    run!(exec, node)
                end
            end
        end
    end

    return ctx
end

"""
`ParallelExecutor` is an Executor which creates a Julia `Task` for each
`DispatchNode`, spawns each of those tasks on the processes available to Julia,
and waits for them to complete.
`ParallelExecutor`'s `run!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type ParallelExecutor <: Executor
end

function run!(exec::ParallelExecutor, ctx::DispatchContext)
    @sync begin
        for i = 1:length(ctx.graph.nodes)
            if !isready(ctx.graph.nodes[i])
                @spawn begin
                    node = ctx.graph.nodes[i]
                    fetch_deps!(node)
                    run!(exec, node)
                end
            end
        end
    end

    return ctx
end
