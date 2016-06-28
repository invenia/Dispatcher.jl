abstract Executor

Base.run(exec::Executor, node::DispatchNode) = nothing


type AsyncExecutor <: Executor
end

function Base.run(exec::AsyncExecutor, op::Op)
    return put!(op.result, op.func(op.args...; op.kwargs...))
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
