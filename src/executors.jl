import Iterators: chain

"""
Handles execution of `DispatchContext`s.

A type `T <: Executor` must implement `dispatch!(::T, ::DispatchContext)`
and may optionally implement `run!(::T, ::DispatchNode)`.

The function call tree will look like this when an executor is run:
```
run!(exec, context)
    prepare!(exec, context)
        prepare!(exec, nodes[i])
    dispatch!(exec, context)
        run!(exec, nodes[i])
```
"""
abstract Executor

immutable ExecutorError{T} <: DispatcherError
    msg::T
end

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
prepare!(exec::Executor, node::DispatchNode) = nothing

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
run!(exec::Executor, node::DispatchNode) = nothing

"""
An Executor-agnostic `prepare!` method for `Op` which replaces its result field
with a fresh, empty one.
"""
function prepare!(exec::Executor, op::Op)
    op.result = DeferredFuture()
    return nothing
end

"""
An Executor-agnostic `run!` method for `Op` which stores its function's
output in its `result` `DeferredFuture`. Arguments to the function which are
`DispatchNode`s are substituted with their value when running.
"""
function run!(exec::Executor, op::Op)
    args = map(op.args) do arg
        if isa(arg, DispatchNode)
            return fetch(arg)
        else
            return arg
        end
    end

    kwargs = map(op.kwargs) do kwarg
        if isa(kwarg.second, DispatchNode)
            return (kwarg.first => fetch(kwarg.second))
        else
            return kwarg
        end
    end

    return put!(op.result, op.func(args...; kwargs...))
end

"""
A pre-processing `run!` method which runs a subset of a graph, ending in
`nodes` and using `input_nodes` to replace nodes with fixed values (and
ignoring nodes for which all paths descend to `input_nodes`).

Returns `nodes`.
"""
function run!{T<:DispatchNode, S<:DispatchNode}(
    exec::Executor,
    ctx::DispatchContext,
    nodes::AbstractArray{T},
    input_nodes::AbstractArray{S}=DispatchNode[];
    input_map::Associative=Dict{DispatchNode, Any}(),
)
    reduced_ctx = copy(ctx)
    input_node_keys = DispatchNode[
        n for n in chain(input_nodes, keys(input_map))
    ]

    reduced_ctx.graph = subgraph(ctx.graph, nodes, input_node_keys)

    # replace nodes in input_map with their values
    for (node, val) in chain(zip(input_nodes, imap(fetch, input_nodes)), input_map)
        node_id = reduced_ctx.graph.nodes[node]
        reduced_ctx.graph.nodes[node_id] = DataNode(val)
    end

    run!(exec, reduced_ctx)

    return nodes
end


"""
The `run!` function prepares a `DispatchContext` for dispatch and then
dispatches `run!` calls for all nodes in its graph.

Users will almost never want to add methods to this function for different
`Executor` subtypes; overriding `dispatch!` is the preferred pattern.
"""
function run!(exec::Executor, ctx::DispatchContext)
    if is_cyclic(ctx.graph.graph)
        throw(ExecutorError(
            "Dispatcher can only run graphs without circular dependencies",
        ))
    end

    prepare!(exec, ctx)
    dispatch!(exec, ctx)
end

"""
This function `prepare!`s all nodes for execution.
"""
function prepare!(exec::Executor, ctx::DispatchContext)
    for node in nodes(ctx.graph)
        prepare!(exec, node)
    end

    return nothing
end

"""
Accepts a `DispatchContext` and an `Executor` and calls `run!` for each node
in the `DispatchContext` using the `Executor`. In almost all cases, a custom
`Executor` will provide a `dispatch!` method which distributes work to nodes.
"""
function dispatch! end

"""
`AsyncExecutor` is an `Executor` which spawns a local Julia `Task` for each
`DispatchNode` and waits for them to complete.
`AsyncExecutor`'s `dispatch!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type AsyncExecutor <: Executor
end

function dispatch!(exec::AsyncExecutor, ctx::DispatchContext)
    @sync begin
        for i = 1:length(ctx.graph.nodes)
            if !isready(ctx.graph.nodes[i])
                @async begin
                    node = ctx.graph.nodes[i]
                    # fetch_deps!(node)
                    run!(exec, node)
                end
            end
        end
    end

    return ctx
end

"""
`ParallelExecutor` is an `Executor` which creates a Julia `Task` for each
`DispatchNode`, spawns each of those tasks on the processes available to Julia,
and waits for them to complete.
`ParallelExecutor`'s `dispatch!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type ParallelExecutor <: Executor
end

function dispatch!(exec::ParallelExecutor, ctx::DispatchContext)
    @sync begin
        for i = 1:length(ctx.graph.nodes)
            if !isready(ctx.graph.nodes[i])
                @spawn begin
                    node = ctx.graph.nodes[i]
                    # fetch_deps!(node)
                    run!(exec, node)
                end
            end
        end
    end

    return ctx
end
