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
A `DispatchNode` represents a unit of computation that can be run.
A `DispatchNode` may depend on other `DispatchNode`s, which are returned from
the `dependencies` function.
"""
abstract DispatchNode <: Base.AbstractRemoteRef

# default methods assume there is no synchronization involved in retrieving
# data
Base.isready(dn::DispatchNode) = true
Base.wait(dn::DispatchNode) = nothing

"""
Unless given a `dependencies` method, a `DispatchNode` will be assumed to have
no dependencies.
"""
dependencies(node::DispatchNode) = ()

# fallback compare DispatchNodes only by object id
# avoids definition for Base.AbstractRemoteRef
Base.:(==)(a::DispatchNode, b::DispatchNode) = a === b

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
prepare!(node::DispatchNode) = nothing

"""
A blank method for no-op nodes or nodes which simply reference other nodes.
"""
run!(node::DispatchNode) = nothing


"""
A `DataNode` is a `DispatchNode` which wraps a piece of static data.
"""
type DataNode{T} <: DispatchNode
    data::T
end

Base.fetch(dn::DataNode) = dn.data

"""
An `Op` is a `DispatchNode` which wraps a function which is executed when the
`Op` is run.
The result of that function call is stored in the `result` `DeferredFuture`.
Any `DispatchNode`s which appear in the args or kwargs values will be noted as
dependencies.
This is the most common `DispatchNode`.
"""
@auto_hash_equals type Op <: DispatchNode
    result::DeferredFuture
    func::Function
    args
    kwargs
end

Op(func::Function, args...; kwargs...) = Op(DeferredFuture(), func, args, kwargs)

function dependencies(node::Op)
    filter(x->isa(x, DispatchNode), chain(
        node.args,
        imap(pair->pair[2], node.kwargs)
    ))
end

Base.isready(op::Op) = isready(op.result)
Base.wait(op::Op) = wait(op.result)

"""
`fetch` will grab the result of the `Op` and throw
`DependencyError` in the condition that the result is a
`DependencyError`.
"""
function Base.fetch(op::Op)
    ret = fetch(op.result)

    if isa(ret, DependencyError)
        throw(ret)
    end

    return ret
end

"""
`prepare!` method for `Op` which replaces its result field
with a fresh, empty one.
"""
function prepare!(op::Op)
    op.result = DeferredFuture()
    return nothing
end

"""
`run!` method for `Op` which stores its function's
output in its `result` `DeferredFuture`.
Arguments to the function which are `DispatchNode`s
are substituted with their value when running.
"""
function run!(op::Op)
    args = map(op.args) do arg
        if isa(arg, DispatchNode)
            if isa(arg, Op)
                info("Waiting on arg = $(arg.result)")
            end
            return fetch(arg)
        else
            return arg
        end
    end

    kwargs = map(op.kwargs) do kwarg
        if isa(kwarg.second, DispatchNode)
            if isa(kwarg.second, Op)
                info("Waiting on kwarg = $(kwarg.second.result)")
            end
            return (kwarg.first => fetch(kwarg.second))
        else
            return kwarg
        end
    end

    return put!(op.result, op.func(args...; kwargs...))
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
end

dependencies(node::IndexNode) = (node.node,)

Base.fetch(node::IndexNode) = fetch(node.node)[node.index]
Base.isready(node::IndexNode) = isready(node.node)
Base.wait(node::IndexNode) = wait(node.node)

# Here we implement iteration on DispatchNodes in order to perform the tuple
# unpacking of function results which people expect. The end result is this:
#   x = Op(Func, arg)
#   a, b = x
#   @assert a == Result(x, 1)
#   @assert b == Result(x, 2)

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

NodeSet() = NodeSet(Dict{Int, DispatchNode}(), ObjectIdDict())

Base.length(ns::NodeSet) = length(ns.id_dict)

Base.in(node::DispatchNode, ns::NodeSet) = node in keys(ns.node_dict)

function Base.push!(ns::NodeSet, node::DispatchNode)
    if !(node in ns)
        new_number = length(ns) + 1
        ns[new_number] = node  # sets reverse mapping as well
    end

    return ns
end

"Return the node numbers of all nodes in `nodes` which are present in `ns`"
function Base.findin(nodes, ns::NodeSet)
    numbers = Int[]
    for node in nodes
        number = get(ns.node_dict, node, 0)
        if number != 0
            push!(numbers, number)
        end
    end

    return numbers
end

"Return an iterable of all nodes stored in the `NodeSet`"
nodes(ns::NodeSet) = keys(ns.node_dict)

Base.getindex(ns::NodeSet, id::Int) = ns.id_dict[id]
Base.getindex(ns::NodeSet, node::DispatchNode) = ns.node_dict[node]

# there is no setindex!(::NodeSet, ::Int, ::DispatchNode) because of the way
# LightGraphs stores graphs as contiguous ranges of integers.

"Replaces the node corresponding to `id` with `node`"
function Base.setindex!(ns::NodeSet, node::DispatchNode, id::Int)
    if id in keys(ns.id_dict)
        old_node = ns.id_dict[id]
        delete!(ns.node_dict, old_node)
    end

    ns.node_dict[node] = id
    ns.id_dict[id] = node
    ns
end
