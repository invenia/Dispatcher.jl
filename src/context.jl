"""
`DispatchContext` holds the computation graph and `DispatchNode` lookup tables.
It can also hold arbitrary key-value pairs of metadata.
"""
type DispatchContext
    graph
    nodes::NodeSet
    meta::Dict{Any, Any}
end

"""
Creates an empty `DispatchContext` with keyword arguments stored in metadata.
"""
function DispatchContext(; kwargs...)
    ctx = DispatchContext(DiGraph(), NodeSet(), Dict{Any, Any}())
    for (k, v) in kwargs
        ctx.meta[k] = v
    end

    return ctx
end

Base.getindex(ctx::DispatchContext, key) = ctx.meta[key]
Base.setindex!(ctx::DispatchContext, value, key) = ctx.meta[key] = value

"""
Adds a `DispatchNode` to the `DispatchContext`'s graph and records
dependencies.

Returns the `DispatchNode` which was added.
"""
function Base.push!(ctx::DispatchContext, node::DispatchNode)
    node_number = push!(ctx.nodes, node)

    for _ in (nv(ctx.graph) + 1):(node_number)
        add_vertex!(ctx.graph)
    end

    deps = dependencies(node)
    dep_numbers = findin(deps, ctx.nodes)

    for dep_number in dep_numbers
        add_edge!(ctx.graph, dep_number, node_number)
    end

    return node
end
