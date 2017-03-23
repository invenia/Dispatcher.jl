import Iterators: chain

"""
An `Executor` handles execution of `DispatchContext`s.

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
    retries(exec::Executor) -> Int

Return the number of retries an executor should perform while attempting to run a node
before giving up. The default `retries` method returns `0`.
"""
retries(exec::Executor) = 0

"""
    retry_on(exec::Executor) -> Vector{Function}

Return the vector of predicates which accept an `Exception` and return `true` if a node can
and should be retried (and `false` otherwise). The default `retry_on` method returns
`Function[]`.
"""
retry_on(exec::Executor) = Function[]

"""
    run!(exec, ctx, nodes, input_nodes; input_map, throw_error) -> DispatchResult

Run a subset of a graph, ending in `nodes`, and using `input_nodes`/`input_map` to replace
nodes with fixed values (and ignoring nodes for which all paths descend to `input_nodes`).

# Arguments

* `exec::Executor`: the executor which will execute this context
* `ctx::DispatchContext`: the context which will be executed
* `nodes::AbstractArray{T<:DispatchNode}`: the nodes whose results we are interested in
* `input_nodes::AbstractArray{T<:DispatchNode}`: "root" nodes of the subgraph which will be
  replaced with their fetched values

# Keyword Arguments

* `input_map::Associative=Dict{DispatchNode, Any}()`: dict keys are "root" nodes of the
  subgraph which will be replaced with the dict values
* `throw_error::Bool`: whether to throw any `DependencyError`s immediately (see `dispatch!`
  documentation for more information)

# Returns

* `Vector{DispatchResult}`: an array containing a `DispatchResult` for each node in `nodes`,
  in that order.

# Throws

* `ExecutorError`: if the context's graph contains a cycle
* `CompositeException`/`DependencyError`: see documentation for `dispatch!`
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

    if is_cyclic(reduced_ctx.graph.graph)
        throw(ExecutorError(
            "Dispatcher can only run graphs without circular dependencies",
        ))
    end

    # replace nodes in input_map with their values
    for (node, val) in chain(zip(input_nodes, imap(fetch, input_nodes)), input_map)
        node_id = reduced_ctx.graph.nodes[node]
        reduced_ctx.graph.nodes[node_id] = DataNode(val)
    end

    # add_cleanup_nodes!(reduced_ctx; exclude=union(nodes, input_nodes))

    prepare!(exec, reduced_ctx)
    node_results = dispatch!(exec, reduced_ctx; throw_error=throw_error)

    # select the results requested by the `nodes` argument
    return DispatchResult[node_results[reduced_ctx.graph.nodes[node]] for node in nodes]
end

"""
    add_cleanup_nodes!(ctx::DispatchContext) -> DispatchContext

For all nodes with children in a given context, add a `CleanupNode` to the graph which will
wait for the child nodes to complete, then clean up the node's data.

Return the first argument.
"""
function add_cleanup_nodes!(
    ctx::DispatchContext;
    exclude::Vector=DispatchNode[],
)
    graphcat(ctx.graph.graph)

    for parent_node in collect(nodes(ctx))
        child_nodes = collect(
            DispatchNode,
            filter(out_neighbors(ctx.graph, parent_node)) do node
                !isa(node, CleanupNode) && !(node in exclude)
            end,
        )

        if !isempty(child_nodes)
            cleanup_node = add!(ctx, CleanupNode(parent_node, child_nodes))
        end
    end

    graphcat(ctx.graph.graph)

    return ctx
end

"""
    run!(exec::Executor, ctx::DispatchContext; kwargs...)

The `run!` function prepares a `DispatchContext` for dispatch and then
dispatches `run!` calls for all nodes in its graph.

Users will almost never want to add methods to this function for different
`Executor` subtypes; overriding `dispatch!` is the preferred pattern.

Return an array containing a `Result{DispatchNode, DependencyError}` for each leaf node.
"""
function run!(exec::Executor, ctx::DispatchContext; kwargs...)
    return run!(exec, ctx, collect(DispatchNode, leaf_nodes(ctx.graph)); kwargs...)
end

"""
    prepare!(exec::Executor, ctx::DispatchContext)

This function `prepare!`s a context for execution.
Call `prepare!` on each node.
"""
function prepare!(exec::Executor, ctx::DispatchContext)
    for node in nodes(ctx.graph)
        prepare!(node)
    end

    return nothing
end

"""
    dispatch!(exec::Executor, ctx::DispatchContext; throw_error=true) -> Vector

The default `dispatch!` method uses asyncmap over all nodes in the context to call
`dispatch!(exec, node)`. These `dispatch!` calls for each node are wrapped in various retry
and error handling methods.

## Wrapping Details

1. All nodes are wrapped in a try catch which waits on the value returned from the
   `dispatch!(exec, node)` call.
   Any errors are caught and used to create `DependencyError`s which are thrown.
   If no errors are produced then the node is returned.

   **NOTE**: All errors thrown by trying to run `dispatch!(exec, node)` are wrapped in a
   `DependencyError`.

2. The aformentioned wrapper function is used in a retry wrapper to rerun failed nodes
   (up to some limit).
   The wrapped function will only be retried iff the error produced by
   `dispatch!(::executor, ::DispatchNode`) passes one of the retry functions specific to
   that `Executor`.
   By default the `AsyncExecutor` has no `retry_on` functions and the `ParallelExecutor`
   only has `retry_on` functions related to the loss of a worker process during execution.

3. A node may enter a failed state if it exits the retry wrapper with an exception.
   This may occur if an exception is thrown while executing a node and it does not pass any
   of the `retry_on` conditions for the `Executor` or too many attempts to run the node have
   been made.
   In the situation where a node has entered a failed state and the node is an `Op` then
   the `op.result` is set to the `DependencyError`, signifying the node's failure to any
   dependent nodes.
   Finally, if `throw_error` is true then the `DependencyError` will be immediately thrown
   in the current process without allowing other nodes to finish.
   If `throw_error` is false then the `DependencyError` is not thrown and it will be
   returned in the array of passing and failing nodes.

## Arguments

* `exec::Executor`: the executor we're running
* `ctx::DispatchContext`: the context of nodes to run

## Keyword Arguments

* `throw_error::Bool=true`: whether or not to throw the `DependencyError` for failed nodes

## Returns

* `Vector{Union{DispatchNode, DependencyError}}`: a list of `DispatchNode`s or
  `DependencyError`s for failed nodes

## Throws

* `dispatch!` has the same behaviour on exceptions as `asyncmap` and `pmap`.
  In 0.5 this will throw a `CompositeException` containing `DependencyError`s, while
  in 0.6 this will simply throw the first `DependencyError`.

## Usage

### Example 1

Assuming we have some uncaught application error:

```julia
exec = AsyncExecutor()
ctx = DispatchContext()
n1 = add!(ctx, Op()->3)
n2 = add!(ctx, Op()->4)
failing_node = add!(ctx, Op(()->throw(ErrorException("ApplicationError"))))
dep_node = add!(n -> println(n), failing_node)  # This will fail as well
```

Then `dispatch!(exec, ctx)` will throw a `DependencyError` and
`dispatch!(exec, ctx; throw_error=false)` will return an array of passing nodes and the
`DependencyError`s (ie: `[n1, n2, DependencyError(...), DependencyError(...)]`).

### Example 2

Now if we want to retry our node on certain errors we can do:

```julia
exec = AsyncExecutor(5, [e -> isa(e, HttpError) && e.status == "503"])
ctx = DispatchContext()
n1 = add!(ctx, Op()->3)
n2 = add!(ctx, Op()->4)
http_node = add!(ctx, Op(()->http_get(...)))
```

Assuming that the `http_get` function does not error 5 times the call to
`dispatch!(exec, ctx)` will return [n1, n2, http_node].
If the `http_get` function either:

  1. fails with a different status code
  2. fails with something other than an `HttpError` or
  3. throws an `HttpError` with status "503" more than 5 times

then we'll see the same failure behaviour as in the previous example.
"""
function dispatch!(exec::Executor, ctx::DispatchContext; throw_error=true)
    ns = ctx.graph.nodes

    function run_inner!(id::Int)
        logger = get_logger(current_module())

        node = ns[id]

        try
            if isa(node, Union{Op, IndexNode})
                info(logger, "Running node $id - $(typeof(node)) -> result $(node.result)")
                reset!(ns[id].result)
            else
                info(logger, "Running node $id - $(typeof(node))")
            end

            cond = dispatch!(exec, node)
            # info(logger, "Waiting on $cond")
            wait(cond)
            info(logger, "Node $id complete.")
        catch err
            warn(logger, "Node $id errored with $err")

            if isa(err, RemoteException)

                throw(DependencyError(
                    err.captured.ex, err.captured.processed_bt, id
                ))
            else
                # Necessary because of a bug with empty stacktraces
                # in base, but will be fixed in 0.6
                # see https://github.com/JuliaLang/julia/issues/19655
                trace = try
                    catch_stacktrace()
                catch
                    StackFrame[]
                end

                throw(DependencyError(err, trace, id))
            end
        end

        return ns[id]
    end

    """
        on_error_inner!(err::Exception)

    Log and throw an exception.
    This is the default behaviour.
    """
    function on_error_inner!(err::Exception)
        logger = get_logger(current_module())
        warn(logger, "Unhandled error $(typeof(err))")
        throw(err)
    end

    """
        on_error_inner!(err::DependencyError) -> DependencyError

    When a dependency error occurs while attempting to run a node, put that dependency error
    in that node's result.
    Throw the error if `dispatch!` was called with `throw_error=true`, otherwise returns the
    error.
    """
    function on_error_inner!(err::DependencyError)
        logger = get_logger(current_module())
        warn(logger, "Handling DependencyError on $(err.id)")

        node = ctx.graph.nodes[err.id]
        if isa(node, Union{Op, IndexNode})
            reset!(node.result)
            put!(node.result, err)
        end

        if throw_error
            throw(err)
        end

        return err
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
        retry_on=allow_retry(retry_on(exec)),
        retry_n=retries(exec),
        on_error=on_error_inner!
    )

    NOTE: see issue https://github.com/JuliaLang/julia/issues/19652
    for more details.
    ```
    =#
    f = Base.wrap_on_error(
        Base.wrap_retry(
            run_inner!,
            allow_retry(retry_on(exec)),
            retries(exec),
            Base.DEFAULT_RETRY_MAX_DELAY
        ),
        on_error_inner!
    )

    return asyncmap(f, 1:length(ctx.graph.nodes))
end

"""
`AsyncExecutor` is an `Executor` which schedules a local Julia `Task` for each
`DispatchNode` and waits for them to complete.
`AsyncExecutor`'s `dispatch!` method will complete as long as each
`DispatchNode`'s `run!` method completes and there are no cycles in the
computation graph.
"""
type AsyncExecutor <: Executor
    retries::Int
    retry_on::Vector{Function}
end

"""
    AsyncExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> AsyncExecutor

`retries` is the number of times the executor is to retry a failed node.
`retry_on` is a vector of predicates which accept an `Exception` and return `true` if a
node can and should be retried (and `false` otherwise).

Return a new AsyncExecutor.
"""
function AsyncExecutor(retries=5, retry_on::Vector{Function}=Function[])
    return AsyncExecutor(retries, retry_on)
end

"""
    dispatch!(exec::ParallelExecutor, node::DispatchNode) -> Task

`dispatch!` takes the `AsyncExecutor` and a `DispatchNode` to run.
The `run!` method on the node is called within an `@async` block and the resulting `Task` is
returned.
This is the defining method of `AsyncExecutor`.
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
    retries::Int
    retry_on::Vector{Function}

    """
        ParallelExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> ParallelExecutor

    `retries` is the number of times the executor is to retry a failed node.
    `retry_on` is a vector of predicates which accept an `Exception` and return `true` if a
    node can and should be retried (and `false` otherwise).
    """
    function ParallelExecutor(retries=5, retry_on::Vector{Function}=Function[])
        # The `ProcessExitedException` is the most common error and is the expected behaviour
        # in julia, but depending on when worker processes die we can see other exceptions related
        # to writing to streams and sockets or in the worst case a race condition with
        # adding and removing pids on the manager process.
        default_retry_on = [
            # Occurs when calling `fetch(f)` on a future where the remote process has already exited.
            # In the case of an `f = @spawn mycode; fetch(f)` the `ProcessExitedException` could
            # occur if the process `mycode` is being run dies/exits before we have fetched the result.
            (e) -> isa(e, ProcessExitedException),

            # If we are in the middle of fetching data and the process is killed we
            # could get an ArgumentError saying that the stream was closed or unusable.
            (e) -> begin
                isa(e, ArgumentError) && contains(e.msg, "stream is closed or unusable")
            end,

            # Julia appears to have a race condition where the worker process is removed at the
            # same time as `@spawn` is selecting a pid which results in a negative pid.
            # This is extremely hard to reproduce, but has happened a few times.
            (e) -> begin
                isa(e, ArgumentError) && contains(e.msg, "IntSet elements cannot be negative")
            end,

            # Similar to the "stream is closed or unusable" error, we can get an error
            # attempting to write to the unknown socket (of a process that has been killed)
            (e) -> begin
                isa(e, ErrorException) && contains(e.msg, "attempt to send to unknown socket")
            end
        ]

        new(retries, append!(default_retry_on, retry_on))
    end
end

"""
    dispatch!(exec::ParallelExecutor, node::DispatchNode) -> Future

`dispatch!` takes the `ParallelExecutor` and a `DispatchNode` to run.
The `run!` method on the node is called within an `@spawn` block and the resulting
`Future` is returned.
This is the defining method of `ParallelExecutor`.
"""
dispatch!(exec::ParallelExecutor, node::DispatchNode) = @spawn run!(node)

"""
    retries(exec::Union{AsyncExecutor, ParallelExecutor}) -> Int

Return the number of retries per node.
"""
retries(exec::Union{AsyncExecutor, ParallelExecutor}) = exec.retries

"""
    retry_on(exec::Union{AsyncExecutor, ParallelExecutor}) -> Vector{Function}

Return the array of retry conditions.
"""
retry_on(exec::Union{AsyncExecutor, ParallelExecutor}) = exec.retry_on

"""
    allow_retry(conditions::Vector{Function}) -> Function

`allow_retry` takes an array of functions that take a `DependencyError` and return a `Bool`.
The returned function will return true if any of the conditions hold, otherwise it will
return false.
"""
function allow_retry(conditions::Vector{Function})
    function inner_allow_retry(de::DependencyError)
        logger = get_logger(current_module())
        ret = any(f -> tmp = f(de.err), conditions)
        info(logger, "Retry ($ret) on $(de.err)")
        return ret
    end

    return inner_allow_retry
end
