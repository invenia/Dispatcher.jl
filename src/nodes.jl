"""
`DependencyError` wraps any errors (and corresponding traceback)
that occur on the dependency of a given nodes.

This is important for passing failure conditions to dependent nodes
after a failed number of retries.

NOTE: our `trace` field is a Union of `Vector{Any}` and `StackTrace`
because we could be storing the traceback from a
`CompositeException` (inside a `RemoteException`) which is of type `Vector{Any}`
"""
immutable DependencyError{T<:Exception} <: DispatcherError
    err::T
    trace::Union{Vector{Any}, StackTrace}
    id::Int
end

Base.showerror(io::IO, de::DependencyError) = showerror(io, de.err, de.trace, backtrace=false)

"""
    summary(de::DependencyError)

Retuns a string representation of the error with
only the internal `Exception` type and the `id`
"""
function Base.summary(de::DependencyError)
    err_type = replace(string(typeof(de.err)), "Dispatcher.", "")
    return "DependencyError<$err_type, $(de.id)>"
end

"""
A `DispatchNode` represents a unit of computation that can be run.
A `DispatchNode` may depend on other `DispatchNode`s, which are returned from
the `dependencies` function.
"""
abstract DispatchNode <: Base.AbstractRemoteRef

typealias DispatchResult Result{DispatchNode, DependencyError}

"""
    has_label(node::DispatchNode) -> Bool

Returns true or false as to whether the
node has a label (ie: a `get_label(node)` method)
"""
has_label(node::DispatchNode) = false

"""
    isready(node::DispatchNode) -> Bool

Determine whether a node has an available result.
The default method assumes no synchronization is involved in retrieving that result.
"""
Base.isready(node::DispatchNode) = true

"""
    wait(node::DispatchNode)

Block the current task until a node has a result available.
"""
Base.wait(node::DispatchNode) = nothing

"""
    dependencies(node::DispatchNode) -> Tuple{Vararg{DispatchNode}}

Return all dependencies which must be ready before executing this node.
Unless given a `dependencies` method, a `DispatchNode` will be assumed to have
no dependencies.
"""
dependencies(node::DispatchNode) = ()

# fallback compare DispatchNodes only by object id
# avoids definition for Base.AbstractRemoteRef
Base.:(==)(a::DispatchNode, b::DispatchNode) = a === b

"""
    prepare!(node::DispatchNode)

Execute some action on a node before dispatching nodes via an `Executor`.
The default method performs no action.
"""
prepare!(node::DispatchNode) = nothing

"""
    run!(node::DispatchNode)

Execute a node's action as part of dispatch.
The default method performs no action.
"""
run!(node::DispatchNode) = nothing

"""
A `DataNode` is a `DispatchNode` which wraps a piece of static data.
"""
@auto_hash_equals type DataNode{T} <: DispatchNode
    data::T
end

"""
    fetch{T}(node::DataNode{T}) -> T

Immediately return the data contained in a `DataNode`.
"""
Base.fetch(node::DataNode) = node.data

"""
An `Op` is a `DispatchNode` which wraps a function which is executed when the `Op` is run.
The result of that function call is stored in the `result` `DeferredFuture`.
Any `DispatchNode`s which appear in the args or kwargs values will be noted as
dependencies.
This is the most common `DispatchNode`.
"""
@auto_hash_equals type Op <: DispatchNode
    result::DeferredFuture
    func::Function
    label::String
    args
    kwargs
end

function Op(func::Function, args...; kwargs...)
    Op(
        DeferredFuture(),
        func,
        string(Symbol(func)),
        args,
        kwargs,
    )
end

"""
    summary(op::Op)

Returns a string representation of the `Op`
with its label and the args/kwargs types.

NOTE: if an arg/kwarg is a `DispatchNode` with a label
it will be printed with that arg.
"""
function Base.summary(op::Op)
    args = join(map(value_summary, op.args), ", ")
    kwargs = join(
        map(op.kwargs) do kwarg
            "$(kwarg[1]) => $(value_summary(kwarg[2]))"
        end,
        ", "
    )

    all_args = join(filter(!isempty, [op.label, args, kwargs]), ", ")
    return "Op<$all_args>"
end

"""
    has_label(op::Op) -> Bool

Always return true as an `Op` will always
have a label.
"""
has_label(op::Op) = true

"""
    get_label(op::Op) -> String

Returns the op.label.
"""
get_label(op::Op) = op.label

"""
    set_label!(op::Op, label::String)

Manually set the label for the op.
"""
set_label!(op::Op, label::String) = op.label = label

"""
    dependencies(op::Op) -> Tuple{Verarg{DispatchNode}}

Return all dependencies which must be ready before executing this `Op`.
This will be all `DispatchNode`s in the `Op`'s function `args` and `kwargs`.
"""
function dependencies(op::Op)
    filter(x->isa(x, DispatchNode), chain(
        op.args,
        imap(pair->pair[2], op.kwargs)
    ))
end

"""
    isready(op::Op) -> Bool

Determine whether an `Op` has an available result.
"""
Base.isready(op::Op) = isready(op.result)

"""
    wait(op::Op)

Wait until an `Op` has an available result.
"""
Base.wait(op::Op) = wait(op.result)

"""
    fetch(op::Op) -> Any

Return the result of the `Op`. Block until it is available. Throw `DependencyError` in the
event that the result is a `DependencyError`.
"""
function Base.fetch(op::Op)
    ret = fetch(op.result)

    if isa(ret, DependencyError)
        throw(ret)
    end

    return ret
end

"""
    prepare!(op::Op)

Replace an `Op`'s result field with a fresh, empty one.
"""
function prepare!(op::Op)
    op.result = DeferredFuture()
    return nothing
end

"""
    run!(op::Op)

Fetch an `Op`'s dependencies and execute its function. Store the result in its
`result::DeferredFuture` field.
"""
function run!(op::Op)
    # fetch dependencies into a Dict{DispatchNode, Any}
    deps = asyncmap(dependencies(op)) do node
        debug(logger, "Waiting on $(summary(node))")
        node => fetch(node)
    end |> Dict

    args = map(op.args) do arg
        if isa(arg, DispatchNode)
            return deps[arg]
        else
            return arg
        end
    end

    kwargs = map(op.kwargs) do kwarg
        if isa(kwarg.second, DispatchNode)
            return (kwarg.first => deps[kwarg.second])
        else
            return kwarg
        end
    end

    put!(op.result, op.func(args...; kwargs...))
    return nothing
end

"""
An `IndexNode` refers to an element of the return value of a `DispatchNode`.
It is meant to handle multiple return values from a `DispatchNode`.

Example:
```julia
n1, n2 = add!(ctx, Op(()->divrem(5, 2)))
run(exec, ctx)

@assert fetch(n1) == 2
@assert fetch(n2) == 1
```

In this example, `n1` and `n2` are created as `IndexNode`s pointing to the
`Op` at index 1 and index 2 respectively.
"""
@auto_hash_equals type IndexNode{T<:DispatchNode} <: DispatchNode
    node::T
    index::Int
    result::DeferredFuture
end

IndexNode(node::DispatchNode, index) = IndexNode(node, index, DeferredFuture())

"""
    summary(node::IndexNode)

Returns a string representation of the IndexNode with a summary of the wrapped
node and the node index.
"""
Base.summary(node::IndexNode) = "IndexNode<$(value_summary(node.node)), $(node.index)>"

"""
    dependencies(node::IndexNode) -> Tuple{DispatchNode}

Return the dependency that this node will fetch data (at a certain index) from.
"""
dependencies(node::IndexNode) = (node.node,)

"""
    fetch(node::IndexNode) -> Any

Return the stored result of indexing.
"""
function Base.fetch(node::IndexNode)
    fetch(node.result)
end

"""
    isready(node::IndexNode) -> Bool

Determine whether an `IndexNode` has an available result.
"""
Base.isready(node::IndexNode) = isready(node.result)

"""
    wait(node::IndexNode)

Wait until an `IndexNode` has an available result.
"""
Base.wait(node::IndexNode) = wait(node.result)

"""
    prepare!(node::IndexNode)

Replace an `IndexNode`'s result field with a fresh, empty one.
"""
function prepare!(node::IndexNode)
    node.result = DeferredFuture()
    return nothing
end

"""
    run!(node::IndexNode) -> DeferredFuture

Fetch data from the `IndexNode`'s parent at the `IndexNode`'s index, performing the indexing
operation on the process where the data lives. Store the data from that index in a
`DeferredFuture` in the `IndexNode`.
"""
function run!{T<:Union{Op, IndexNode}}(node::IndexNode{T})
    put!(node.result, node.node.result[node.index])
    return nothing
end

"""
    run!(node::IndexNode) -> DeferredFuture

Fetch data from the `IndexNode`'s parent at the `IndexNode`'s index, performing the indexing
operation on the process where the data lives. Store the data from that index in a
`DeferredFuture` in the `IndexNode`.
"""
function run!(node::IndexNode)
    put!(node.result, fetch(node.node)[node.index])
    return nothing
end

@auto_hash_equals type CleanupNode{T<:DispatchNode} <: DispatchNode
    parent_node::T
    child_nodes::Vector{DispatchNode}
    is_finished::DeferredFuture
end

"""
    CleanupNode(parent_node::DispatchNode, child_nodes::Vector{DispatchNode}) -> CleanupNode

Create a `CleanupNode` to clean up the parent node's results when the child nodes have
completed.
"""
function CleanupNode(parent_node, child_nodes)
    CleanupNode(parent_node, child_nodes, DeferredFuture())
end

"""
    summary(node::CleanupNode)

Returns a string representation of the CleanupNode with a summary of the wrapped
parent node.
"""
Base.summary(node::CleanupNode) = "CleanupNode<$(value_summary(node.parent))>"

"""
    dependencies(node::CleanupNode) -> Tuple{Vararg{DispatchNode}}

Return the nodes the `CleanupNode` must wait for before cleaning up (the parent and child
nodes).
"""
dependencies(node::CleanupNode) = (node.parent_node, node.child_nodes...)

function Base.fetch{T<:CleanupNode}(node::T)
    throw(ArgumentError("DispatchNodes of type $T cannot have dependencies"))
end

"""
    isready(node::CleanupNode) -> Bool

Determine whether a `CleanupNode` has completed its cleanup.
"""
Base.isready(node::CleanupNode) = isready(node.is_finished)

"""
    wait(node::CleanupNode)

Block the current task until a `CleanupNode` has completed its cleanup.
"""
Base.wait(node::CleanupNode) = wait(node.is_finished)

"""
    prepare!(node::IndexNode)

Replace an `CleanupNode`'s completion status field with a fresh, empty one.
"""
function prepare!(node::CleanupNode)
    node.is_finished = DeferredFuture()
    return nothing
end

"""
    run!(node::CleanupNode{Op})

Wait for all of the `CleanupNode`'s dependencies to finish, then clean up the parent node's
data.
"""
function run!{T<:Op}(node::CleanupNode{T})
    for dependency in dependencies(node)
        wait(dependency)
    end

    # finalize(node.parent_node.result)
    reset!(node.parent_node.result)
    # finalize(node.parent_node.result)
    @everywhere gc()
    put!(node.is_finished, true)
    return nothing
end

# Here we implement iteration on DispatchNodes in order to perform the tuple
# unpacking of function results which people expect. The end result is this:
#   x = Op(Func, arg)
#   a, b = x
#   @assert a == IndexNode(x, 1)
#   @assert b == IndexNode(x, 2)

Base.start(node::DispatchNode) = 1
Base.next(node::DispatchNode, state::Int) = IndexNode(node, state), state + 1
Base.done(node::DispatchNode, state::Int) = false
Base.eltype{T<:DispatchNode}(node::T) = IndexNode{T}

Base.getindex(node::DispatchNode, index::Int) = IndexNode(node, index)


"""
`NodeSet` stores a correspondence between intances of `DispatchNode`s and
the `Int` indices used by LightGraphs to denote vertices. It is only used by
`DispatchContext`.
"""
type NodeSet
    id_dict::Dict{Int, DispatchNode}
    node_dict::ObjectIdDict
end

"""
    NodeSet() -> NodeSet

Create a new empty `NodeSet`.
"""
NodeSet() = NodeSet(Dict{Int, DispatchNode}(), ObjectIdDict())

"""
    length(ns::NodeSet) -> Integer

Return the number of nodes in a node set.
"""
Base.length(ns::NodeSet) = length(ns.id_dict)

"""
    in(node::DispatchNode, ns::NodeSet) -> Bool

Determine whether a node is in a node set.
"""
Base.in(node::DispatchNode, ns::NodeSet) = node in keys(ns.node_dict)

"""
    push!(ns::NodeSet, node::DispatchNode) -> NodeSet

Add a node to a node set. Return the first argument.
"""
function Base.push!(ns::NodeSet, node::DispatchNode)
    if !(node in ns)
        new_number = length(ns) + 1
        ns[new_number] = node  # sets reverse mapping as well
    end

    return ns
end

"""
    findin(ns::NodeSet, nodes) -> Vector{Int}

Return the node numbers of all nodes in the node set whcih are present in the `nodes`
iterable of `DispatchNode`s.
"""
function Base.findin(ns::NodeSet, nodes)
    numbers = Int[]
    for node in nodes
        number = get(ns.node_dict, node, 0)
        if number != 0
            push!(numbers, number)
        end
    end

    return numbers
end

"""
    nodes(ns::NodeSet) ->

Return an iterable of all nodes stored in the `NodeSet`
"""
nodes(ns::NodeSet) = keys(ns.node_dict)

"""
    getindex(ns::NodeSet, node_id::Int) -> DispatchNode

Return the `DispatchNode` from a node set corresponding to a given integer id.
"""
Base.getindex(ns::NodeSet, node_id::Int) = ns.id_dict[node_id]

"""
    getindex(ns::NodeSet, node::DispatchNode) -> Int

Return the integer id from a node set corresponding to a given `DispatchNode`.
"""
Base.getindex(ns::NodeSet, node::DispatchNode) = ns.node_dict[node]

# there is no setindex!(::NodeSet, ::Int, ::DispatchNode) because of the way
# LightGraphs stores graphs as contiguous ranges of integers.

"""
    setindex!(ns::NodeSet, node::DispatchNode, node_id::Int) -> NodeSet

Replace the node corresponding to a given integer id with a given `DispatchNode`. Return
the first argument.
"""
function Base.setindex!(ns::NodeSet, node::DispatchNode, node_id::Int)
    if node_id in keys(ns.id_dict)
        old_node = ns.id_dict[node_id]
        delete!(ns.node_dict, old_node)
    end

    ns.node_dict[node] = node_id
    ns.id_dict[node_id] = node
    ns
end

function value_summary(val)
    if isa(val, DispatchNode)
        # Remove module name "Dispatcher." if present
        pat = "Dispatcher."

        if has_label(val)
            type_name = replace(string(typeof(val)), pat, "")
            label = get_label(val)
            return "$type_name<$label>"
        else
            return replace(summary(val), pat, "")
        end
    else
        return summary(val)
    end
end
