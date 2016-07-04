"""
Handles execution of `DispatchContext`s.

A type `T <: Executor` must implement `Base.run(::T, ::DispatchContext)`
and may optionally implement `Base.run(::T, ::DispatchNode)`.
"""
abstract Executor

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
Base.run(exec::Executor, node::DispatchNode) = nothing

"""
An Executor-agnostic `Base.run` method for `Op` which stores its function's
output in its `result` `DeferredFuture`.
"""
function Base.run(exec::Executor, op::Op)
    return put!(op.result, op.func(op.args...; op.kwargs...))
end


"""
`AsyncExecutor` is an Executor which spawns a local Julia `Task` for each
`DispatchNode` and waits for them to complete.
`AsyncExecutor`'s `Base.run` method will complete as long as each
`DispatchNode`'s `Base.run` method completes and there are no cycles in the
computation graph.
"""
type AsyncExecutor <: Executor
end

function Base.run(exec::AsyncExecutor, ctx::DispatchContext)
    @sync begin
        for i = 1:length(ctx.nodes)
            @async begin
                node = ctx.nodes[i]
                fetch_deps!(node)
                run(exec, node)
            end
        end
    end
end

"""
`ParallelExecutor` is an Executor which creates a Julia `Task` for each
`DispatchNode`, spawns each of those tasks on the processes available to Julia,
and waits for them to complete.
`ParallelExecutor`'s `Base.run` method will complete as long as each
`DispatchNode`'s `Base.run` method completes and there are no cycles in the
computation graph.
"""
type ParallelExecutor <: Executor
end

function Base.run(exec::ParallelExecutor, ctx::DispatchContext)
    @sync begin
        for i = 1:length(ctx.nodes)
            @spawn begin
                node = ctx.nodes[i]
                fetch_deps!(node)
                run(exec, node)
            end
        end
    end
end
