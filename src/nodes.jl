abstract DispatchNode <: Base.AbstractRemoteRef

dependencies(node::DispatchNode) = ()
Base.:(==)(a::DispatchNode, b::DispatchNode) = a === b


type Op <: DispatchNode
    result::Future
    func::Function
    args
    kwargs
end

# Futures may be tied to the machine they're created on, which might mean that
# if a future is created on P1, then storing a result in it on P2 and getting
# the result on P3 may cause the data to go P2->P1->P3. The solution to this is
# to make the future field Nullable and only initialize the future when the
# task is about to run.
Op(func::Function, args...; kwargs...) = Op(Future(), func, args, kwargs)

function dependencies(node::Op)
    filter(x->isa(x, DispatchNode), node.args)
end

Base.isready(op::Op) = isready(op.result)
Base.fetch(op::Op) = fetch(op.result)
Base.wait(op::Op) = wait(op.result)


type ResultNode{T<:DispatchNode} <: DispatchNode
    node::T
    index::Int
end

dependencies(node::ResultNode) = (node,)

Base.fetch(node::ResultNode) = fetch(node.node)[node.index]
Base.isready(node::ResultNode) = isready(node.node)
Base.wait(node::ResultNode) = wait(node.node)

# Here we implement iteration on Op objects in order to perform the tuple
# unpacking of function results which people expect. The end result is this:
#   x = Op(Func, arg)
#   a, b = x
#   @assert a == Result(x, 1)
#   @assert b == Result(x, 2)

Base.start(node::DispatchNode) = 1
Base.next(node::DispatchNode, state::Int) = ResultNode(node, state), state + 1
Base.done(node::DispatchNode, state::Int) = false


# fetch_deps!(node::DispatchNode) = nothing

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


type NodeSet
    id_dict::Dict{Int, DispatchNode}
    node_dict::ObjectIdDict
end

NodeSet() = NodeSet(Dict{Int, DispatchNode}(), ObjectIdDict())

Base.length(ns::NodeSet) = length(ns.id_dict)

Base.in(node::DispatchNode, ns::NodeSet) = node in keys(ns.node_dict)

function Base.push!(ns::NodeSet, node::DispatchNode)
    if node in ns
        return ns.node_dict[node]
    else
        new_number = length(ns) + 1
        ns.id_dict[new_number] = node
        ns.node_dict[node] = new_number
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
