"""
`DependencyError` wraps any errors (and corresponding traceback)
that occur on the dependency of a given nodes.

This is important for passing failure conditions to dependent nodes
after a failed number of retries.

**NOTE**: our `trace` field is a Union of `Vector{Any}` and `StackTrace`
because we could be storing the traceback from a
`CompositeException` (inside a `RemoteException`) which is of type `Vector{Any}`
"""
struct DependencyError{T<:Exception} <: DispatcherError
    err::T
    trace::Union{Vector{Any}, Base.StackTraces.StackTrace}
    id::Int
end

Base.showerror(io::IO, de::DependencyError) = showerror(io, de.err, de.trace, backtrace=false)

"""
    summary(de::DependencyError)

Retuns a string representation of the error with
only the internal `Exception` type and the `id`
"""
function Base.summary(de::DependencyError)
    err_type = replace(string(typeof(de.err)), "Dispatcher." => "")
    return "DependencyError<$err_type, $(de.id)>"
end

"""
A `DispatchNode` represents a unit of computation that can be run.
A `DispatchNode` may depend on other `DispatchNode`s, which are returned from
the [`dependencies`](@ref) function.
"""
abstract type DispatchNode <: DeferredFutures.AbstractRemoteRef end

const DispatchResult = Result{DispatchNode, DependencyError}

"""
    has_label(node::DispatchNode) -> Bool

Returns true or false as to whether the
node has a label (ie: a [`get_label(::DispatchNode)`](@ref) method)
"""
has_label(node::DispatchNode) = false

"""
    get_label(node::DispatchNode) -> String

Returns a node's label.
By default, `DispatchNode`s do not support labels, so this method will error.
"""
get_label(node::T) where {T<:DispatchNode} = error("$T does not implement labels")

"""
    set_label!(node::DispatchNode, label)

Sets a node's label.
By default, `DispatchNode`s do not support labels, so this method will error.
Actual method implementations should return their second argument.
"""
set_label!(node::T, label) where {T<:DispatchNode} = error("$T does not implement labels")

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
    fetch(node::DispatchNode) -> Any

Fetch a node's result if available, blocking until it is available.
All subtypes of `DispatchNode` should implement this, so the default method throws an error.
"""
Base.fetch(node::T) where {T<:DispatchNode} = error("$T should implement $fetch, but doesn't!")

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

Execute some action on a node before dispatching nodes via an [`Executor`](@ref).
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
@auto_hash_equals mutable struct DataNode{T} <: DispatchNode
    data::T
end

"""
    show(io::IO, node::DataNode)

Print a simplified string representation of the `DataNode` with its data.
"""
function Base.show(io::IO, node::DataNode)
    print(io, typeof(node).name.name, "($(node.data))")
end

"""
    fetch{T}(node::DataNode{T}) -> T

Immediately return the data contained in a `DataNode`.
"""
Base.fetch(node::DataNode) = node.data

"""
An `Op` is a [`DispatchNode`](@ref) which wraps a function which is executed when the `Op`
is run.
The result of that function call is stored in the `result` `DeferredFuture`.
Any `DispatchNode`s which appear in the args or kwargs values will be noted as
dependencies.
This is the most common `DispatchNode`.
"""
@auto_hash_equals mutable struct Op <: DispatchNode
    result::DeferredFuture
    func::Base.Callable
    label::String
    args
    kwargs
end

"""
    Op(func::Function, args...; kwargs...) -> Op

Construct an `Op` which represents the delayed computation of `func(args...; kwargs)`.
Any [`DispatchNode`](@ref)s which appear in the args or kwargs values will be noted as
dependencies.
The default label of an `Op` is the name of `func`.
"""
function Op(func::Base.Callable, args...; kwargs...)
    Op(
        DeferredFuture(),
        func,
        string(Symbol(func)),
        args,
        kwargs,
    )
end

"""
    @op func(...)

The `@op` macro makes it more convenient to construct [`Op`](@ref) nodes. It translates a
function call into an `Op` call, effectively deferring the computation.

```julia
a = @op sort(1:10; rev=true)
```
is equivalent to
```julia
a = Op(sort, 1:10; rev=true)
```
"""
macro op(ex)
    # parameters expressions only appear when kwargs are separated with a semicolon
    # parameters expressions must be the second arg in a :call Expr because reasons
    param_idx = findfirst(ex.args) do arg_ex
        isa(arg_ex, Expr) && arg_ex.head === :parameters
    end

    if param_idx !== nothing
        ex.args[1:param_idx] = circshift(ex.args[1:param_idx], 1)
    end

    ex.head = :call
    ex.args = [
        Dispatcher.Op,
        ex.args...
    ]

    esc(ex)
end

"""
    show(io::IO, op::Op)

Print a simplified string representation of the `Op` with its DeferredFuture
RemoteChannel parameters, its function, and label.
"""
function Base.show(io::IO, op::Op)
    print(io, "$(typeof(op).name.name)($(op.result),$(op.func),\"$(op.label)\")")
end

"""
    summary(op::Op)

Returns a string representation of the `Op`
with its label and the args/kwargs types.

**NOTE**: if an arg/kwarg is a [`DispatchNode`](@ref) with a label
it will be printed with that arg.
"""
function Base.summary(op::Op)
    args = join(map(value_summary, op.args), ", ")
    kwargs = join(
        map(collect(op.kwargs)) do kwarg
            "$(kwarg[1]) => $(value_summary(kwarg[2]))"
        end,
        ", "
    )
    all_args = join(filter(!isempty, [op.label, args, kwargs]), ", ")
    return "Op<$all_args>"
end

"""
    has_label(::Op) -> Bool

Always return `true` as an `Op` will always have a label.
"""
has_label(op::Op) = true

"""
    get_label(op::Op) -> String

Returns the `op.label`.
"""
get_label(op::Op) = op.label

"""
    set_label!(op::Op, label::AbstractString)

Set the op's label.
Returns its second argument.
"""
set_label!(op::Op, label::AbstractString) = op.label = label

"""
    dependencies(op::Op) -> Tuple{Verarg{DispatchNode}}

Return all dependencies which must be ready before executing this `Op`.
This will be all [`DispatchNode`](@ref)s in the `Op`'s function `args` and `kwargs`.
"""
function dependencies(op::Op)
    Iterators.filter(x->isa(x, DispatchNode), Iterators.flatten((
        op.args,
        imap(pair->pair[2], op.kwargs)
    )))
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

Return the result of the `Op`. Block until it is available. Throw [`DependencyError`](@ref)
in the event that the result is a `DependencyError`.
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

    kwargs = map(collect(op.kwargs)) do kwarg
        if isa(kwarg.second, DispatchNode)
            kwarg.first => deps[kwarg.second]
        else
            kwarg
        end
    end

    put!(op.result, op.func(args...; kwargs...))
    return nothing
end

"""
An `IndexNode` refers to an element of the return value of a [`DispatchNode`](@ref).
It is meant to handle multiple return values from a `DispatchNode`.

Example:
```julia
n1, n2 = Op(() -> divrem(5, 2))
run!(exec, [n1, n2])

@assert fetch(n1) == 2
@assert fetch(n2) == 1
```

In this example, `n1` and `n2` are created as `IndexNode`s pointing to the
[`Op`](@ref) at index `1` and index `2` respectively.
"""
@auto_hash_equals mutable struct IndexNode{T<:DispatchNode} <: DispatchNode
    node::T
    index::Int
    result::DeferredFuture
end

"""
    IndexNode(node::DispatchNode, index) -> IndexNode

Create a new `IndexNode` referring to the result of `node` at `index`.
"""
IndexNode(node::DispatchNode, index) = IndexNode(node, index, DeferredFuture())

"""
    show(io::IO, node::IndexNode)

Print a simplified string representation of the `IndexNode` with its node, index, and
result DeferredFuture RemoteChannel parameters.
"""
function Base.show(io::IO, node::IndexNode)
    print(io, "$(typeof(node).name.name)($(node.node),$(node.index),$(node.result))")
end

"""
    summary(node::IndexNode)

Returns a string representation of the `IndexNode` with a summary of the wrapped
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
function run!(node::IndexNode{T}) where T<:Union{Op, IndexNode}
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

@auto_hash_equals mutable struct CleanupNode{T<:DispatchNode} <: DispatchNode
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

function Base.fetch(node::T) where T<:CleanupNode
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
    prepare!(node::CleanupNode)

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
function run!(node::CleanupNode{T}) where T<:Op
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

@auto_hash_equals mutable struct CollectNode{T<:DispatchNode} <: DispatchNode
    nodes::Vector{T}
    result::DeferredFuture
    label::String
end

"""
    CollectNode{T<:DispatchNode}(nodes::Vector{T}) -> CollectNode{T}

Create a node which gathers an array of nodes and stores an array of their results in its
result field.
"""
function CollectNode(nodes::Vector{T}) where T<:DispatchNode
    num_nodes = length(nodes)
    plural_ending = num_nodes != 1 ? "s" : ""

    CollectNode(
        nodes,
        DeferredFuture(),
        "$num_nodes $(T.name.name)$plural_ending",
    )
end

"""
    CollectNode(nodes) -> CollectNode{DispatchNode}

Create a `CollectNode` from any iterable of nodes.
"""
CollectNode(nodes) = CollectNode(collect(DispatchNode, nodes))

"""
    dependencies{T<:DispatchNode}(node::CollectNode{T}) -> Vector{T}

Return the nodes this depends on which this node will collect.
"""
dependencies(node::CollectNode) = node.nodes

"""
    fetch(node::CollectNode) -> Vector

Return the result of the collection.
Block until it is available.
"""
Base.fetch(node::CollectNode) = fetch(node.result)

"""
    isready(node::CollectNode) -> Bool

Determine whether a `CollectNode` has an available result.
"""
Base.isready(node::CollectNode) = isready(node.result)

"""
    wait(node::CollectNode)

Block until a `CollectNode` has an available result.
"""
Base.wait(node::CollectNode) = wait(node.result)

"""
    prepare!(node::CollectNode)

Initialize a `CollectNode` with a fresh result `DeferredFuture`.
"""
function prepare!(node::CollectNode)
    node.result = DeferredFuture()
    return nothing
end

"""
    run!(node::CollectNode)

Collect all of a `CollectNode`'s dependencies' results into a Vector and store that in this
node's result field.
Returns `nothing`.
"""
function run!(node::CollectNode)
    parent_node_results = asyncmap(dependencies(node)) do parent_node
        debug(logger, "Waiting on $(summary(parent_node))")
        fetch(parent_node)
    end

    put!(node.result, parent_node_results)
    return nothing
end

"""
    get_label(node::CollectNode) -> String

Returns the node.label.
"""
get_label(node::CollectNode) = node.label

"""
    set_label!(node::CollectNode, label::AbstractString) -> AbstractString

Set the node's label.
Returns its second argument.
"""
set_label!(node::CollectNode, label::AbstractString) = node.label = label

"""
    has_label(::CollectNode) -> Bool

Always return `true` as a `CollectNode` will always have a label.
"""
has_label(::CollectNode) = true

"""
    show(io::IO, node::CollectNode)

Print a simplified string representation of the `CollectNode` with its nodes Vector,
result DeferredFuture RemoteChannel parameters, and its label.
"""
function Base.show(io::IO, node::CollectNode)
    print(io, typeof(node).name.name, "(DispatchNode[")
    join(io, node.nodes, ",")
    print(io, "],$(node.result),\"$(node.label)\")")
end

"""
    summary(node::CollectNode)

Returns a string representation of the `CollectNode` with its label.
"""
Base.summary(node::CollectNode) = value_summary(node)

# Here we implement iteration on DispatchNodes in order to perform the tuple
# unpacking of function results which people expect. The end result is this:
#   x = Op(Func, arg)
#   a, b = x
#   @assert a == IndexNode(x, 1)
#   @assert b == IndexNode(x, 2)
function Base.iterate(node::DispatchNode, state::Int=1)
    return IndexNode(node, state), state + 1
end

Base.eltype(::Type{T}) where {T<:DispatchNode} = IndexNode{T}

Base.getindex(node::DispatchNode, index::Int) = IndexNode(node, index)


"""
`NodeSet` stores a correspondence between intances of [`DispatchNode`](@ref)s and
the `Int` indices used by `LightGraphs` to denote vertices. It is only used by
[`DispatchGraph`](@ref).
"""
mutable struct NodeSet
    id_dict::Dict{Int, DispatchNode}
    node_dict::_IdDict
end

"""
    NodeSet() -> NodeSet

Create a new empty `NodeSet`.
"""
NodeSet() = NodeSet(Dict{Int, DispatchNode}(), _IdDict())

"""
    show(io::IO, ns::NodeSet)

Print a simplified string representation of the `NodeSet` with its nodes ordered by integer
index.
"""
function Base.show(io::IO, ns::NodeSet)
    print(io, typeof(ns).name.name, "(DispatchNode[")
    join(io, values(sort(ns.id_dict)), ",")
    print(io, "])")
end

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
    nodes(ns::NodeSet) ->

Return an iterable of all nodes stored in the `NodeSet`
"""
nodes(ns::NodeSet) = keys(ns.node_dict)

"""
    getindex(ns::NodeSet, node_id::Int) -> DispatchNode

Return the [`DispatchNode`](@ref) from a node set corresponding to a given integer id.
"""
Base.getindex(ns::NodeSet, node_id::Int) = ns.id_dict[node_id]

"""
    getindex(ns::NodeSet, node::DispatchNode) -> Int

Return the integer id from a node set corresponding to a given [`DispatchNode`](@ref).
"""
Base.getindex(ns::NodeSet, node::DispatchNode) = ns.node_dict[node]

# there is no setindex!(::NodeSet, ::Int, ::DispatchNode) because of the way
# LightGraphs stores graphs as contiguous ranges of integers.

"""
    setindex!(ns::NodeSet, node::DispatchNode, node_id::Int) -> NodeSet

Replace the node corresponding to a given integer id with a given [`DispatchNode`](@ref).
Return the first argument.
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
    if isa(val, DispatchNode) && has_label(val)
        type_name = typeof(val).name.name
        label = get_label(val)
        return "$type_name<$label>"
    else
        return summary(val)
    end
end
