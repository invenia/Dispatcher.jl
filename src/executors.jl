abstract Executor

Base.run(exec::Executor, node::DispatchNode) = nothing

function Base.run(exec::Executor, op::Op)
    return put!(op.result, op.func(op.args...; op.kwargs...))
end


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
