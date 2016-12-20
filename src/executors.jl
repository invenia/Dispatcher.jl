import Iterators: chain

"""
Handles execution of `DispatchContext`s.

A type `T <: Executor` must implement `dispatch!(::T, ::DispatchNode)`
and may optionally implement `dispatch!(::T, ::DispatchContext; throw_error=true)`.

The function call tree will look like this when an executor is run:
```
run!(exec, context)
    prepare!(exec, context)
        prepare!(nodes[i])
    dispatch!(exec, context)
        dispatch!(exec, nodes[i])
            run!(nodes[i])
```

NOTE: Currently, it is expected that `dispatch!(::T, ::DispatchNode)` returns
something to wait on (ie: `Task`, `Future`, `Channel`, `DispatchNode`, etc)
"""
abstract Executor

immutable ExecutorError{T} <: DispatcherError
    msg::T
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
    throw_error=true
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

    return run!(exec, reduced_ctx; throw_error=throw_error)
end


"""
The `run!` function prepares a `DispatchContext` for dispatch and then
dispatches `run!` calls for all nodes in its graph.

Users will almost never want to add methods to this function for different
`Executor` subtypes; overriding `dispatch!` is the preferred pattern.
"""
function run!(exec::Executor, ctx::DispatchContext; throw_error=true)
    if is_cyclic(ctx.graph.graph)
        throw(ExecutorError(
            "Dispatcher can only run graphs without circular dependencies",
        ))
    end

    prepare!(exec, ctx)
    return dispatch!(exec, ctx; throw_error=throw_error)
end

"""
This function `prepare!`s all nodes for execution.
"""
function prepare!(exec::Executor, ctx::DispatchContext)
    for node in nodes(ctx.graph)
        prepare!(node)
    end

    return nothing
end

"""
The default `dispatch!(exec::Executor, ctx::DispatchContext; throw_error=true)`
uses asyncmap overall nodes in the context to call `dispatch!(exec, node)`.
These `dispatch!` call for each node are wrapped in various retry and error
handling methods.

Wrapping details:

1. All nodes are wrapped in a try catch which waits on the value
returned from the `dispatch!(exec, node)` call. Any errors are caught and used
to create `DependencyError`s which are thrown. If no errors are produced then the
node is returned.

2. The aformentioned wrapper function is used in a retry wrapper to rerun failed
nodes (up to some limit). Conditions specified by the specific `Executor` are used
to determine retry conditions.

3. A node may enter a state where it cannot be retried
(either the failure is not one of the retry conditions or we have already
retried the max number of times).
In this case, if the error is a `DependencyError` (which it should be) then the error
will be thrown if `throw_error` is true. If the node for the `DependencyError` is an
`Op` then the `DependencyError` is placed in the result of that `Op` to signify
the failure to potential dependents. If a node cannot be retried and the
exception is not a `DependencyError` then the error is simply thrown.

Args:
- `exec`: is the executor we're running.
- `ctx`: the context of nodes to run.

Kwargs:
- `throw_error`: whether or not to throw the `DependencyError` for failed nodes.

Returns:
- `Array{Union{DispatchNode, DependencyError}}` - returns a list of
`DispatchNode`s or `DependencyError`s for failed nodes.

Throws:
- `DependencyError` for failed nodes if `throw_error` is true
- Any other uncaught exceptions (indicating an issue with the executor)
"""
function dispatch!(exec::Executor, ctx::DispatchContext; throw_error=true)
    ns = ctx.graph.nodes

    function run_inner!(id::Int)
        node = ns[id]

        try
            if isa(node, Op)
                info("Running node $id - $(typeof(node)) -> result $(node.result)")
                reset!(ns[id].result)
            else
                info("Running node $id - $(typeof(node))")
            end

            cond = dispatch!(exec, node)
            # info("Waiting on $cond")
            wait(cond)
            info("Node $id complete.")
        catch exc
            warn("Node $id errored with $exc")

            if isa(exc, RemoteException)

                throw(DependencyError(
                    exc.captured.ex, exc.captured.processed_bt, id
                ))
            else
                # Necessary because of bug with empty stacktraces in base
                trace = try
                    catch_stacktrace()
                catch
                    StackFrame[]
                end

                throw(DependencyError(exc, trace, id))
            end
        end

        return ns[id]
    end

    """
    Default behaviour is to throw unknown exceptions.
    """
    function on_error_inner!(exc)
        warn("Unhandled error $(tyepof(exc))")
        throw(exc)
    end

    """
    Handle `DependencyError`s appropriately.
    """
    function on_error_inner!(exc::DependencyError)
        warn("Handling DependencyError on $(exc.id)")

        node = ctx.graph.nodes[exc.id]
        if isa(node, Op)
            reset!(node.result)
            put!(node.result, exc)
        end

        if throw_error
            throw(exc)
        end

        return exc
    end

    #=
    This is necessary because the base pmap call is broken.
    Specifically, if you call `pmap(...; distributed=false)` when
    you only have a single worker process the resulting `asyncmap`
    call will only use the same number of `Task`s as there are workers.
    This will often result in blocking code.

    Our desired `pmap` call is provided below
    ```
    results = pmap(
        run_inner!,
        1:length(ctx.graph.nodes);
        distributed=false,
        retry_on=isretry(retry_on(exec)),
        retry_n=retry_n(exec),
        on_error=on_error_inner!
    )

    NOTE: see issue https://github.com/JuliaLang/julia/issues/19652
    for more details.
    ```
    =#
    f = Base.wrap_on_error(
        Base.wrap_retry(
            run_inner!,
            isretry(retry_on(exec)),
            retry_n(exec),
            Base.DEFAULT_RETRY_MAX_DELAY
        ),
        on_error_inner!
    )

    return asyncmap(f, 1:length(ctx.graph.nodes))
end

"""
`AsyncExecutor` is an `Executor` which spawns a local Julia `Task` for each
`DispatchNode` and waits for them to complete.
`AsyncExecutor`'s `dispatch!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type AsyncExecutor <: Executor
    retry_n::Int
    retry_on::Array{Function}
end

function AsyncExecutor(retry_n=5, retry_on::Array{Function}=Function[])
    return ParallelExecutor(retries, retry_on)
end

" `retry_n` accessor for AsyncExecutor returns the number of retries per node."
retry_n(exec::AsyncExecutor) = exec.retry_n

" `retry_on` accessor for AsyncExecutor returns the array of retry conditions"
retry_on(exec::AsyncExecutor) = exec.retry_on

"""
`dispatch!` takes the `AsyncExecutor` and a `DispatchNode` to run.
The `run!` method on the node is called within an `@async` block and the
resulting `Task` is returned.
"""
dispatch!(exec::AsyncExecutor, node::DispatchNode) = @async run!(node)

"""
`ParallelExecutor` is an `Executor` which creates a Julia `Task` for each
`DispatchNode`, spawns each of those tasks on the processes available to Julia,
and waits for them to complete.
`ParallelExecutor`'s `dispatch!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type ParallelExecutor <: Executor
    retry_n::Int
    retry_on::Array{Function}

    function ParallelExecutor(retries=5, retry_on::Array{Function}=Function[])
        default_retry_on = [
            (exc) -> isa(exc, ProcessExitedException),
            (exc) -> begin
                isa(exc, ArgumentError) && contains(exc.msg, "stream is closed or unusable")
            end,
            (exc) -> begin
                isa(exc, ArgumentError) && contains(exc.msg, "IntSet elements cannot be negative")
            end,
            (exc) -> begin
                isa(exc, ErrorException) && contains(exc.msg, "attempt to send to unknown socket")
            end
        ]

        new(retries, append!(default_retry_on, retry_on))
    end
end

" `retry_n` accessor for AsyncExecutor returns the number of retries per node."
retry_n(exec::ParallelExecutor) = exec.retry_n

" `retry_on` accessor for AsyncExecutor returns the array of retry conditions"
retry_on(exec::ParallelExecutor) = exec.retry_on

"""
`dispatch!` takes the `ParallelExecutor` and a `DispatchNode` to run.
The `run!` method on the node is called within an `@spawn` block and the resulting
`Future` is returned.
"""
dispatch!(exec::ParallelExecutor, node::DispatchNode) = @spawn run!(node)

"""
`isretry` takes an array of functions that take an exception and
return a bool. `isretry` will return true if any of the conditions hold,
otherwise it'll return false.
"""
function isretry(conditions::Array{Function})
    function inner_isretry(de::DependencyError)
        ret = any(f -> tmp = f(de.exc), conditions)
        info("Retry ($ret) on $(de.exc)")
        return ret
    end

    return inner_isretry
end
