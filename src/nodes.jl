"""
A `DispatchNode` represents a unit of computation that can be run.
A `DispatchNode` may depend on other `DispatchNode`s, which are returned from
the `dependencies` function.
"""
abstract DispatchNode <: Base.AbstractRemoteRef

"""
Unless given a `dependencies` method, a `DispatchNode` will be assumed to have
no dependencies.
"""
dependencies(node::DispatchNode) = ()

# compare DispatchNodes only by object id; they must refer to the same memory
Base.:(==)(a::DispatchNode, b::DispatchNode) = a === b


"""
An `Op` is a `DispatchNode` which wraps a function which is executed when the
`Op` is run.
The result of that function call is stored in the `result` `DeferredFuture`.
Any `DispatchNode`s which appear in the args or kwargs values will be noted as
dependencies.
This is the most common `DispatchNode`.
"""
type Op <: DispatchNode
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
Base.fetch(op::Op) = fetch(op.result)
Base.wait(op::Op) = wait(op.result)


"""
An `IndexNode` refers to an element of the return value of a `DispatchNode`.
It is meant to handle multiple return values from a `DispatchNode`.

Example:
```julia
n1, n2 = push!(ctx, Op(()->divrem(5, 2)))
run(exec, ctx)

@assert fetch(n1) == 2
@assert fetch(n2) == 1
```

In this example, `n1` and `n2` are created as `IndexNode`s pointing to the
`Op` at index 1 and index 2 respectively.
"""
type IndexNode{T<:DispatchNode} <: DispatchNode
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


fetch_deps!(node::DispatchNode) = nothing

"""
Replace all `DispatchNode`s with their results in preparation for calling an
`Op`'s function.
"""
function fetch_deps!(node::Op)
    node.args = map(node.args) do arg
        if isa(arg, DispatchNode)
            return fetch(arg)
        else
            return arg
        end
    end

    node.kwargs = map(node.kwargs) do kwarg
        if isa(kwarg.second, DispatchNode)
            return (kwarg.first => fetch(kwarg.second))
        else
            return kwarg
        end
    end
end


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
    if node in ns
        return ns[node]
    else
        new_number = length(ns) + 1
        ns[node] = new_number  # sets reverse mapping as well
        return new_number
    end
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

Base.getindex(ns::NodeSet, id::Int) = ns.id_dict[id]
Base.getindex(ns::NodeSet, node::DispatchNode) = ns.node_dict[node]
Base.setindex!(ns::NodeSet, node::DispatchNode, id::Int) = Base.setindex!(ns, id, node)

function Base.setindex!(ns::NodeSet, id::Int, node::DispatchNode)
    ns.node_dict[node] = id
    ns.id_dict[id] = node
    ns
end
