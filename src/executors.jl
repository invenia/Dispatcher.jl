import Distributed: wrap_on_error, wrap_retry

"""
An `Executor` handles execution of [`DispatchGraph`](@ref)s.

A type `T <: Executor` must implement `dispatch!(::T, ::DispatchNode)`
and may optionally implement `dispatch!(::T, ::DispatchGraph; throw_error=true)`.

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
something to wait on (ie: `Task`, `Future`, `Channel`, [`DispatchNode`](@ref), etc)
"""
abstract type Executor end

struct ExecutorError{T} <: DispatcherError
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
    run!(exec, output_nodes, input_nodes; input_map, throw_error) -> DispatchResult

Create a graph, ending in `output_nodes`, and using `input_nodes`/`input_map` to
replace nodes with fixed values (and ignoring nodes for which all paths descend to
`input_nodes`), then execute it.

# Arguments

* `exec::Executor`: the executor which will execute the graph
* `graph::DispatchGraph`: the graph which will be executed
* `output_nodes::AbstractArray{T<:DispatchNode}`: the nodes whose results we are interested
  in
* `input_nodes::AbstractArray{T<:DispatchNode}`: "root" nodes of the graph which will be
  replaced with their fetched values (dependencies of these nodes are not included in the
  graph)

# Keyword Arguments

* `input_map::Associative=Dict{DispatchNode, Any}()`: dict keys are "root" nodes of the
  subgraph which will be replaced with the dict values (dependencies of these nodes are not
  included in the graph)
* `throw_error::Bool`: whether to throw any [`DependencyError`](@ref)s immediately (see
  [`dispatch!(::Executor, ::DispatchGraph)`](@ref) for more information)

# Returns

* `Vector{DispatchResult}`: an array containing a `DispatchResult` for each node in
  `output_nodes`, in that order.

# Throws

* `ExecutorError`: if the constructed graph contains a cycle
* `CompositeException`/[`DependencyError`](@ref): see documentation for
  [`dispatch!(::Executor, ::DispatchGraph)`](@ref)
"""
function run!(
    exec::Executor,
    output_nodes::AbstractArray{T},
    input_nodes::AbstractArray{S}=DispatchNode[];
    input_map::AbstractDict=Dict{DispatchNode, Any}(),
    throw_error=true
) where {T<:DispatchNode, S<:DispatchNode}
    graph = DispatchGraph(output_nodes, collect(Iterators.flatten((input_nodes, keys(input_map)))))

    if is_cyclic(graph.graph)
        throw(ExecutorError(
            "Dispatcher can only run graphs without circular dependencies",
        ))
    end

    # replace nodes in input_map with their values
    for (node, val) in Iterators.flatten((zip(input_nodes, imap(fetch, input_nodes)), input_map))
        node_id = graph.nodes[node]
        graph.nodes[node_id] = DataNode(val)
    end

    prepare!(exec, graph)
    node_results = dispatch!(exec, graph; throw_error=throw_error)

    # select the results requested by the `nodes` argument
    return DispatchResult[node_results[graph.nodes[node]] for node in output_nodes]
end

"""
    run!(exec::Executor, graph::DispatchGraph; kwargs...)

The `run!` function prepares a [`DispatchGraph`](@ref) for dispatch and then
dispatches [`run!(::DispatchNode)`](@ref) calls for all nodes in its graph.

Users will almost never want to add methods to this function for different
[`Executor`](@ref) subtypes; overriding [`dispatch!(::Executor, ::DispatchGraph)`](@ref)
is the preferred pattern.

Return an array containing a `Result{DispatchNode, DependencyError}` for each leaf node.
"""
function run!(exec::Executor, graph::DispatchGraph; kwargs...)
    if is_cyclic(graph.graph)
        throw(ExecutorError(
            "Dispatcher can only run graphs without circular dependencies",
        ))
    end

    return run!(exec, collect(DispatchNode, leaf_nodes(graph)); kwargs...)
end

"""
    prepare!(exec::Executor, graph::DispatchGraph)

This function prepares a context for execution.
Call [`prepare!(::DispatchNode)`](@ref) on each node.
"""
function prepare!(exec::Executor, graph::DispatchGraph)
    for node in nodes(graph)
        prepare!(node)
    end

    return nothing
end

"""
    dispatch!(exec::Executor, graph::DispatchGraph; throw_error=true) -> Vector

The default `dispatch!` method uses `asyncmap` over all nodes in the context to call
`dispatch!(exec, node)`. These `dispatch!` calls for each node are wrapped in various retry
and error handling methods.

## Wrapping Details

1. All nodes are wrapped in a try catch which waits on the value returned from the
   `dispatch!(exec, node)` call.
   Any errors are caught and used to create [`DependencyError`](@ref)s which are thrown.
   If no errors are produced then the node is returned.

   **NOTE**: All errors thrown by trying to run `dispatch!(exec, node)` are wrapped in a
   `DependencyError`.

2. The aformentioned wrapper function is used in a retry wrapper to rerun failed nodes
   (up to some limit).
   The wrapped function will only be retried iff the error produced by
   `dispatch!(::Executor, ::DispatchNode`) passes one of the retry functions specific to
   that [`Executor`](@ref).
   By default the [`AsyncExecutor`](@ref) has no [`retry_on`](@ref) functions and the
   [`ParallelExecutor`](@ref) only has `retry_on` functions related to the loss of a worker
   process during execution.

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
* `graph::DispatchGraph`: the context of nodes to run

## Keyword Arguments

* `throw_error::Bool=true`: whether or not to throw the `DependencyError` for failed nodes

## Returns

* `Vector{Union{DispatchNode, DependencyError}}`: a list of [`DispatchNode`](@ref)s or
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
n1 = Op(() -> 3)
n2 = Op(() -> 4)
failing_node = Op(() -> throw(ErrorException("ApplicationError")))
dep_node = Op(n -> println(n), failing_node)  # This node will fail as well
graph = DispatchGraph([n1, n2, failing_node, dep_node])
```

Then `dispatch!(exec, graph)` will throw a `DependencyError` and
`dispatch!(exec, graph; throw_error=false)` will return an array of passing nodes and the
`DependencyError`s (ie: `[n1, n2, DependencyError(...), DependencyError(...)]`).

### Example 2

Now if we want to retry our node on certain errors we can do:

```julia
exec = AsyncExecutor(5, [e -> isa(e, HttpError) && e.status == "503"])
n1 = Op(() -> 3)
n2 = Op(() -> 4)
http_node = Op(() -> http_get(...))
graph = DispatchGraph([n1, n2, http_node])
```

Assuming that the `http_get` function does not error 5 times the call to
`dispatch!(exec, graph)` will return [n1, n2, http_node].
If the `http_get` function either:

  1. fails with a different status code
  2. fails with something other than an `HttpError` or
  3. throws an `HttpError` with status "503" more than 5 times

then we'll see the same failure behaviour as in the previous example.
"""
function dispatch!(exec::Executor, graph::DispatchGraph; throw_error=true)
    ns = graph.nodes

    function run_inner!(id::Int)
        node = ns[id]
        run_inner_node!(exec, node, id)
        return ns[id]
    end

    """
        on_error_inner!(err::Exception)

    Log and throw an exception.
    This is the default behaviour.
    """
    function on_error_inner!(err::Exception)
        warn(logger, "Unhandled Error: $err")
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
        notice(logger, "Handling Error: $(summary(err))")

        node = graph.nodes[err.id]
        if isa(node, Union{Op, IndexNode})
            reset!(node.result)
            put!(node.result, err)
        end

        if throw_error
            throw(err)
        end

        return err
    end

    """
        reset_node!(id::Int)

    Reset the node identified by `id` in the `DispatchGraph` before any are executed to
    avoid race conditions where a node gets reset after it has been completed.
    """
    function reset_node!(id::Int)
        node = ns[id]

        if isa(node, Union{Op, IndexNode})
            reset!(ns[id].result)
        end
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
        1:length(graph.nodes);
        distributed=false,
        retry_on=allow_retry(retry_on(exec)),
        retry_n=retries(exec),
        on_error=on_error_inner!
    )

    NOTE: see issue https://github.com/JuliaLang/julia/issues/19652
    for more details.
    ```
    =#
    retry_args = (ExponentialBackOff(; n=retries(exec)), allow_retry(retry_on(exec)))

    wrapped_reset! = Dispatcher.wrap_on_error(
        Dispatcher.wrap_retry(
            reset_node!,
            retry_args...,
        ),
        on_error_inner!
    )

    wrapped_run! = Dispatcher.wrap_on_error(
        Dispatcher.wrap_retry(
            run_inner!,
            retry_args...,
        ),
        on_error_inner!
    )

    len = length(graph.nodes)
    info(logger, "Executing $len graph nodes.")

    for id in 1:len
        wrapped_reset!(id)
    end

    res = asyncmap(wrapped_run!, 1:len; ntasks=div(len * 3, 2))
    info(logger, "All $len nodes executed.")

    return res
end

"""
    run_inner_node!(exec::Executor, node::DispatchNode, id::Int)

Run the `DispatchNode` in the `DispatchGraph` at position `id`. Any error thrown during the
node's execution is caught and wrapped in a [`DependencyError`](@ref).

Typical [`Executor`](@ref) implementations should not need to override this.
"""
function run_inner_node!(exec::Executor, node::DispatchNode, id::Int)
    try
        desc = summary(node)
        info(logger, "Node $id ($desc): running.")

        cond = dispatch!(exec, node)
        debug(logger, "Waiting on $cond")
        fetch(cond)
        info(logger, "Node $id ($desc): complete.")
    catch err
        debug(logger, "Node $id: errored with $err)")

        dep_err = if isa(err, RemoteException)
            DependencyError(
                err.captured.ex, err.captured.processed_bt, id
            )
        else
            DependencyError(err, stacktrace(catch_backtrace()), id)
        end

        debug(logger, "Node $id: throwing $dep_err)")
        throw(dep_err)
    end
end

"""
`AsyncExecutor` is an [`Executor`](@ref) which schedules a local Julia `Task` for each
[`DispatchNode`](@ref) and waits for them to complete.
`AsyncExecutor`'s [`dispatch!(::AsyncExecutor, ::DispatchNode)`](@ref) method will complete
as long as each `DispatchNode`'s [`run!(::DispatchNode)`](@ref) method completes and there
are no cycles in the computation graph.
"""
mutable struct AsyncExecutor <: Executor
    retries::Int
    retry_on::Vector{Function}
end

"""
    AsyncExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> AsyncExecutor

`retries` is the number of times the executor is to retry a failed node.
`retry_on` is a vector of predicates which accept an `Exception` and return `true` if a
node can and should be retried (and `false` otherwise).

Return a new `AsyncExecutor`.
"""
function AsyncExecutor(retries=5, retry_on::Vector{Function}=Function[])
    return AsyncExecutor(retries, retry_on)
end

"""
    dispatch!(exec::AsyncExecutor, node::DispatchNode) -> Task

`dispatch!` takes the `AsyncExecutor` and a `DispatchNode` to run.
The [`run!(::DispatchNode)`](@ref) method on the node is called within a `@async` block
and the resulting `Task` is returned.
This is the defining method of `AsyncExecutor`.
"""
dispatch!(exec::AsyncExecutor, node::DispatchNode) = @async run!(node)

"""
`ParallelExecutor` is an [`Executor`](@ref) which creates a Julia `Task` for each
[`DispatchNode`](@ref), spawns each of those tasks on the processes available to Julia,
and waits for them to complete.
`ParallelExecutor`'s [`dispatch!(::ParallelExecutor, ::DispatchGraph)`](@ref) method will
complete as long as each `DispatchNode`'s [`run!(::DispatchNode)`](@ref) method completes
and there are no cycles in the computation graph.

    ParallelExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> ParallelExecutor

`retries` is the number of times the executor is to retry a failed node.
`retry_on` is a vector of predicates which accept an `Exception` and return `true` if a
node can and should be retried (and `false` otherwise).
Returns a new `ParallelExecutor`.
"""
mutable struct ParallelExecutor <: Executor
    retries::Int
    retry_on::Vector{Function}

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
                isa(e, ArgumentError) && occursin("stream is closed or unusable", e.msg)
            end,

            # Julia appears to have a race condition where the worker process is removed at the
            # same time as `@spawn` is selecting a pid which results in a negative pid.
            # This is extremely hard to reproduce, but has happened a few times.
            (e) -> begin
                isa(e, ArgumentError) && occursin("IntSet elements cannot be negative", e.msg)
            end,

            # Similar to the "stream is closed or unusable" error, we can get an error
            # attempting to write to the unknown socket (of a process that has been killed)
            (e) -> begin
                isa(e, ErrorException) && occursin("attempt to send to unknown socket", e.msg)
            end
        ]

        new(retries, append!(default_retry_on, retry_on))
    end
end

"""
    dispatch!(exec::ParallelExecutor, node::DispatchNode) -> Future

`dispatch!` takes the `ParallelExecutor` and a [`DispatchNode`](@ref) to run.
The [`run!(::DispatchNode)`](@ref) method on the node is called within an `@spawn` block and
the resulting `Future` is returned.
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

`allow_retry` takes an array of functions that take a [`DependencyError`](@ref) and return a
`Bool`.
The returned function will return `true` if any of the conditions hold, otherwise it will
return `false`.
"""
function allow_retry(conditions::Vector{Function})
    function inner_allow_retry(de::DependencyError)
        ret = any(f -> tmp = f(de.err), conditions)
        debug(logger, "Retry ($ret) on $(summary(de))")
        return ret
    end

    return (state, e) -> (state, inner_allow_retry(e))
end
